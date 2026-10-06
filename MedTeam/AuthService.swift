//
//  AuthService.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class AuthService: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    
    static let shared = AuthService()
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        self.userSession = Auth.auth().currentUser
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
            if user != nil {
                Task {
                    try? await UserService.shared.fetchCurrentUser()
                }
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    @MainActor
    func login(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            try await UserService.shared.fetchCurrentUser()
        } catch {
//            print("Debug: Failed to log in - \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func createUser(withEmail email: String, password: String, fullname: String, username: String, credentials: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            try await uploadUserData(withEmail: email, fullname: fullname, username: username, credentials: credentials, id: result.user.uid)
        } catch {
            print("Debug: Failed to create user - \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        self.userSession = nil
        UserService.shared.reset()
    }

    func sendPasswordReset(toEmail email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Student verification

    static func isSchoolEmail(_ email: String) -> Bool {
        let parts = email.lowercased().trimmingCharacters(in: .whitespaces).split(separator: "@")
        return parts.count == 2 && parts[1].hasSuffix(".edu")
    }

    /// Sends a confirmation link to the student's school (.edu) address.
    /// If it isn't their login email, Firebase switches the login email to it once they click the link.
    @MainActor
    func sendSchoolVerification(to schoolEmail: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        let email = schoolEmail.lowercased().trimmingCharacters(in: .whitespaces)
        if user.email?.lowercased() == email {
            try await user.sendEmailVerification()
        } else {
            try await user.sendEmailVerification(beforeUpdatingEmail: email)
        }
        try await UserService.shared.updateFields(["schoolEmail": email])
    }

    /// Returns true once the login email is a verified .edu address, and records it on the profile.
    @MainActor
    func confirmSchoolVerification() async throws -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        try await user.reload()
        guard let refreshed = Auth.auth().currentUser, refreshed.isEmailVerified,
              let email = refreshed.email, Self.isSchoolEmail(email) else { return false }
        try await UserService.shared.updateFields([
            "studentVerified": true,
            "schoolEmail": email,
            "email": email
        ])
        return true
    }

    /// Set after a successful deletion so the login screen can confirm it.
    @Published var didDeleteAccount = false

    /// Permanently deletes the signed-in account. Conversations are kept for the other
    /// participant but show "Deleted user"; pings are removed.
    @MainActor
    func deleteAccount(password: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }

        // Re-authenticate first so Firebase can't reject the final step with
        // requiresRecentLogin after the profile data is already gone.
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)

        let uid = user.uid
        let db = Firestore.firestore()

        let conversations = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: uid).getDocuments()
        for doc in conversations.documents {
            try await doc.reference.updateData(["participantNames.\(uid)": "Deleted user"])
            try await doc.reference.collection("messages").addDocument(data: [
                "senderId": "system",
                "text": "This member deleted their account.",
                "type": Message.MessageType.system.rawValue,
                "createdAt": Timestamp(date: Date()),
                "readBy": [uid]
            ])
        }

        let sent = try await db.collection("pings").whereField("fromUserId", isEqualTo: uid).getDocuments()
        let received = try await db.collection("pings").whereField("toUserId", isEqualTo: uid).getDocuments()
        let batch = db.batch()
        for doc in sent.documents + received.documents { batch.deleteDocument(doc.reference) }
        try await batch.commit()

        // The app doesn't upload photos yet, but remove one if it lives in our Storage bucket.
        if let url = UserService.shared.currentUser?.profileImageUrl,
           url.hasPrefix("gs://") || url.contains("firebasestorage.googleapis.com") {
            try? await Storage.storage().reference(forURL: url).delete()
        }

        try await db.collection("users").document(uid).delete()
        try await user.delete()

        self.userSession = nil
        UserService.shared.reset()
        didDeleteAccount = true
    }

    /// Plain-language text for Firebase Auth / Firestore errors.
    static func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain, let code = AuthErrorCode.Code(rawValue: nsError.code) {
            switch code {
            case .wrongPassword, .invalidCredential:
                return "That email and password don't match. Please try again."
            case .userNotFound:
                return "No account uses that email address."
            case .invalidEmail, .missingEmail:
                return "Please enter a valid email address."
            case .emailAlreadyInUse:
                return "That email is already registered. Try logging in instead."
            case .weakPassword:
                return "Please choose a stronger password (at least 6 characters)."
            case .networkError:
                return "You appear to be offline. Check your connection and try again."
            case .tooManyRequests:
                return "Too many attempts. Please wait a few minutes and try again."
            case .userDisabled:
                return "This account has been disabled. Please contact support."
            case .requiresRecentLogin, .userTokenExpired:
                return "For your security, please log out, log back in, and try again."
            default:
                break
            }
        }
        if nsError.domain == FirestoreErrorDomain, nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
            return "You don't have permission to do that. Please contact support."
        }
        return "Something went wrong. Please try again."
    }
    
    @MainActor
    private func uploadUserData(withEmail email: String, fullname: String, username: String, credentials: String, id: String) async throws {
        var user = User(id: id, email: email, fullname: fullname, username: username, credentials: credentials)
        // Sign-up requires agreeing to the Terms of Use.
        user.termsAcceptedAt = Date()
        do {
            let userData = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(id).setData(userData)
            UserService.shared.currentUser = user
        } catch {
            print("Debug: Failed to upload user data - \(error.localizedDescription)")
            throw error
        }
    }
    
}

