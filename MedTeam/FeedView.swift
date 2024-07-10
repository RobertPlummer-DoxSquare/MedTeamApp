//
//  FeedView.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

//import Foundation
//import SwiftUI
//
//struct FeedView: View {
//var body: some View {
//    Text("Feed")
//    }
//}
//
//struct FeedView_Previews: PreviewProvider {
//    static var previews: some View {
//        FeedView()
//    }
//}

import SwiftUI
import Firebase

struct Hospital: Hashable {
    let id = UUID().uuidString
    let name: String
    let icon: String
    var positions: [String]
}

struct FeedView: View {
    @State private var selectedHospital: Hospital?
    @State private var navigateToUserDataView = false
    @State private var showMenu = false
    @State private var showSettingsView = false

    let hospitals: [Hospital] = [
        Hospital(name: "Moses", icon: "building", positions: ["Doctor", "Nurse", "Technician", "Administrator", "Receptionist"]),
        Hospital(name: "Weiler", icon: "building", positions: ["Doctor", "Nurse", "Technician", "Weiler", "Receptionist"]),
        Hospital(name: "Jacobi", icon: "building", positions: ["Doctor", "Nurse", "Technician", "Administrator", "Receptionist"]),
        Hospital(name: "Wakefield", icon: "building", positions: ["Doctor", "Nurse", "Technician", "Administrator", "Receptionist"]),
        Hospital(name: "North Central Bronx", icon: "building", positions: ["Doctor", "Nurse", "Technician", "Administrator", "Receptionist"])
    ]

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    HospitalSelectionView(selectedHospital: $selectedHospital, hospitals: hospitals)
                }
                .padding()
                .offset(x: showMenu ? 330 : 0)
                .disabled(showMenu)

                if showMenu {
                                  Hamburger(showHamburger: $showMenu, showSettingsView: $showSettingsView)
                                      .frame(maxWidth: .infinity, maxHeight: .infinity)
                                      .background(Color.black.opacity(0.75))
                                      .edgesIgnoringSafeArea(.all)
                              }

                              Button(action: { showMenu.toggle() }) {
                                  Image(systemName: "line.horizontal.3")
                                      .foregroundColor(.white)
                                      .padding()
                                      .background(Color.black)
                                      .cornerRadius(12)
                              }
                              .position(x: 40, y: 40) // Adjust the position to suit your layout
                          }
                      }
                      .sheet(isPresented: $showSettingsView) {
                          Settings()
                      }
                  }
              }
struct HospitalSelectionView: View {
    @Binding var selectedHospital: Hospital?
    @State private var navigateToSurgeryServiceSelection = false
    
    var hospitals: [Hospital]
    
    var body: some View {
        VStack {
            
            Spacer()
            Text("Swipe for more hospitals")
                .font(.headline)
                .padding(.bottom, 10)
            
            
            TabView {
                ForEach(hospitals, id: \.self) { hospital in
                    HospitalIconView(hospital: hospital, selectedHospital: $selectedHospital, navigateToSurgeryServiceSelection: $navigateToSurgeryServiceSelection)
                        .tag(hospital)
                
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .background(
                NavigationLink(
                    destination: SurgeryServiceSelectionView(selectedServices: Binding.constant([]), selectedHospital: $selectedHospital),
                    isActive: $navigateToSurgeryServiceSelection
                ) {
                    EmptyView()
                }
            )
        }
    }
}

struct HospitalIconView: View {
    let hospital: Hospital
    @Binding var selectedHospital: Hospital?
    @Binding var navigateToSurgeryServiceSelection: Bool

    @State private var isBarFloating = false // State variable to control the floating animation
    @State private var isButtonFloating = false // State variable to control the button's floating animation

    var body: some View {
        VStack(spacing: 4) { // Adjust spacing between text and bar
            Text(hospital.name)
                .font(.title)
//                .font(size: 60)
                .padding(.vertical, 6) // Add vertical padding to create space around the text

            // Floating green bar with rounded edges and animation
//            RoundedRectangle(cornerRadius: 1) // Adjust corner radius to make edges round
//                .fill(Color.black)
//                .frame(height: 1) // Decrease the height of the bar to match the size of the text
//                .padding(.horizontal, 16) // Add horizontal padding to match the text
//                .offset(y: isBarFloating ? -1.5 : 0) // Offset the bar up by 1.5 points when isBarFloating is true
//                .onAppear {
//                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever()) {
//                        self.isBarFloating = true // Start the floating animation
//                    }
//                }

            // Floating animated button
            Button(action: {
                selectedHospital = hospital
                navigateToSurgeryServiceSelection = true
            }) {
                Text("Select")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .offset(y: isButtonFloating ? -20 : 0) // Offset the button up by 20 points when isButtonFloating is true
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever()) {
                    self.isButtonFloating = true // Start the button's floating animation
                }
            }
        }
        .background(selectedHospital == hospital ? Color.blue.opacity(0.3) : Color.clear)
        .cornerRadius(10)
    }
}


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SurgeryService: Identifiable, Hashable {
    var id = UUID()
    var name: String
}

struct SurgeryServiceSelectionView: View {
    @Binding var selectedServices: Set<SurgeryService>
    @Binding var selectedHospital: Hospital?

    let surgeryServices: [SurgeryService] = [
        SurgeryService(name: "Acute Care Surgery"),
        SurgeryService(name: "Vascular Surgery"),
        SurgeryService(name: "Colorectal Surgery"),
        SurgeryService(name: "Surgical Oncology"),
        SurgeryService(name: "SICU"),
        SurgeryService(name: "Trauma"),
        SurgeryService(name: "General Surgery"),
        SurgeryService(name: "Minimally Invasive Surgery"),
        SurgeryService(name: "Plastic Surgery"),
        SurgeryService(name: "Breast Surgery"),
        SurgeryService(name: "Hepatobiliary Surgery"),
        SurgeryService(name: "Orthopaedic Surgery")
    ]

    var body: some View {
        VStack {
            Text("Select Your Surgery Service")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 20)

            Spacer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(surgeryServices, id: \.self) { service in
                        ServiceView(service: service, selectedServices: $selectedServices, surgeryServices: surgeryServices)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
            }

            Spacer()

            NavigationLink(destination: PositionSelectionView(selectedHospital: $selectedHospital, selectedServices: $selectedServices)) {
                Text("Next")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("")
    }
}

struct ServiceView: View {
    let service: SurgeryService
    @Binding var selectedServices: Set<SurgeryService>
    let surgeryServices: [SurgeryService]
    @State private var selectedService: SurgeryService?
    @State private var blink: Bool = false
    @State private var magnify: Bool = false
    @State private var recentSelection: SurgeryService?
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(height: 40)
                Circle()
                            .fill(selectedService == service && selectedServices.contains(service) ? (blink ? Color.blue : Color.blue.opacity(0.3)) : Color.blue.opacity(0.3))
                            .frame(width: magnify ? 60 : 40, height: magnify ? 60 : 40)
                            .offset(x: 0, y: 0)
                            .scaleEffect(magnify ? 1.2 : 1)
                            .shadow(color: recentSelection == service ? Color.blue.opacity(0.7) : Color.clear, radius: 20, x: 0, y: 0)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: magnify ? 2 : 0)
                                    .scaleEffect(magnify ? 1.2 : 1)
                                    .opacity(blink ? 1 : 0)
                                    .animation(Animation.easeInOut(duration: 0.5).repeatForever())
                            )
                
                Text(service.name)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(selectedServices.contains(service) ? Color.blue.opacity(0.9) : Color.black.opacity(1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            .onTapGesture {
                handleServiceSelection(service)
                magnify = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        magnify = false
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(selectedServices.contains(service) ? Color.blue.opacity(1) : Color.clear, lineWidth: 2)
        )
    }
    
    private func handleServiceSelection(_ service: SurgeryService) {
        // Set magnify to false for the previously selected service
        if let previousService = selectedService, previousService != service {
            magnify = false
        }

        // Toggle selection for the current service
        if selectedService == service {
            selectedService = nil
            magnify = false
        } else {
            selectedService = service
            magnify = true
        }
        
        recentSelection = service

        // Update the set of selected services
        if selectedServices.contains(service) {
            selectedServices.remove(service)
        } else {
            selectedServices.insert(service)
        }

        saveSelectedService(service)
    }
    
    private func saveSelectedService(_ service: SurgeryService) {
        guard let currentUserUID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUserUID)
        
        // Update the database with the selected service
        userRef.updateData([
            "selectedSurgeryServices": [service.name] // Set the array with the single selected service
        ]) { error in
            if let error = error {
                print("Error updating selected surgery services in Firestore: \(error.localizedDescription)")
            } else {
                print("Selected Surgery Service \(service.name) saved successfully to Firestore")
            }
        }
    }
}

struct SurgeryServiceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SurgeryServiceSelectionView(selectedServices: .constant([]), selectedHospital: .constant(nil))
    }
}

struct PositionSelectionView: View {
    @Binding var selectedHospital: Hospital?
    @State private var selectedPositionIndex: Int?
    @State private var isNightMode = false
    @Binding var selectedServices: Set<SurgeryService>

    let positions = ["Student", "PA", "Intern", "Consult", "Chief", "Fellow", "Attending"]

    var body: some View {
        VStack {
            Spacer() // Top Spacer to push content to the center

            VStack {
                HStack {
                    Spacer()
                    Toggle(isOn: $isNightMode) {
                        Text(isNightMode ? "Night" : "Day")
                            .font(.headline)
                            .foregroundColor(isNightMode ? .white : .black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(isNightMode ? Color.blue : Color.white)
                            .cornerRadius(20)
                    }
                    .padding(.trailing)
                }
                
                Spacer() // Spacer between toggle and text

                Text("Swipe for more positions, tap to select")
                    .font(.headline)
                    .padding(.bottom, 20)

                GeometryReader { geometry in
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(positions.indices, id: \.self) { index in
                                    Button(action: {
                                        selectedPositionIndex = index
                                    }) {
                                        VStack {
                                               Image(systemName: "person.fill")
                                                   .resizable()
                                                   .aspectRatio(contentMode: .fit)
                                                   .frame(width: 50, height: 50)
                                                   .foregroundColor(.black)

                                               Text(positions[index])
                                                   .font(.subheadline)
                                                   .foregroundColor(.primary)
                                           }
                                           .padding()
                                           .background(Color.clear)
                                           .overlay(
                                               RoundedRectangle(cornerRadius: 10)
                                                   .stroke(Color.clear, lineWidth: 2)
                                           )
                                           .padding(.bottom, selectedPositionIndex == index ? 2 : 0)
                                           .overlay(
                                               Rectangle()
                                                   .fill(selectedPositionIndex == index ? Color.blue : Color.clear)
                                                   .frame(height: 2)
                                                   .offset(y: 40)
                                           )
                                       }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }

            Spacer() // Bottom Spacer to push content to the center

            NavigationLink(destination: CalendarSelectionView(
                selectedHospital: $selectedHospital,
                selectedPosition: Binding<String?>(
                    get: {
                        if let index = selectedPositionIndex {
                            return positions[index]
                        } else {
                            return nil
                        }
                    },
                    set: { newValue in
                        if let newPosition = newValue, let index = positions.firstIndex(of: newPosition) {
                            selectedPositionIndex = index
                        } else {
                            selectedPositionIndex = nil
                        }
                    }
                ),
                selectedServices: $selectedServices)
            ) {
                Text("Next")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(selectedPositionIndex == nil)
        }
        .navigationTitle("")
        .onAppear {
            if selectedHospital == nil {
                // Handle case when selectedHospital is nil
            }
        }
    }
}

struct CalendarSelectionView: View {
    @Binding var selectedHospital: Hospital?
    @Binding var selectedPosition: String?
    @Binding var selectedServices: Set<SurgeryService>
    @State private var selectedDays: Set<DateComponents> = []
    @State private var currentDate = Date()
    
    @StateObject private var sessionViewModel = SessionViewModel()
    @State private var navigateToSessionView = false
    @Environment(\.presentationMode) var presentationMode // Add this environment variable

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss() // Dismiss the view to navigate back
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding()
                }
                Spacer()
            }
            .padding(.horizontal)
                     
            Text("Pick your days on service this month")
                .font(.title)
                .padding()

            LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 10) {
                ForEach(daysInMonth(for: currentDate), id: \.self) { day in
                    Button(action: {
                        toggleDay(day)
                    }) {
                        Text("\(day.day!)")
                            .frame(width: 40, height: 40)
                            .foregroundColor(isSelected(day) ? .white : .primary)
                            .background(isSelected(day) ? Color.blue : Color.clear)
                            .clipShape(Circle())
                    }
                    .padding(5)
                    .disabled(isOutsideMonth(day))
                }
            }
            .padding()

            Button("Submit") {
                saveData(selectedServices: selectedServices)
                navigateToSessionView = true
            }
            .padding()
            .disabled(selectedDays.isEmpty)
            
            
            NavigationLink(
                destination: SessionView(
                    sessionViewModel: sessionViewModel,
                    selectedHospital: selectedHospital!,
                    selectedServices: Array(selectedServices).map { $0.name }
                ),
                isActive: $navigateToSessionView
            ) {
                EmptyView()
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }

    private func daysInMonth(for date: Date) -> [DateComponents] {
        var days = [DateComponents]()
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)!
        let numDays = daysInMonth.count
        
        for day in 1...numDays {
            var components = DateComponents()
            components.day = day
            components.month = calendar.component(.month, from: date)
            components.year = calendar.component(.year, from: date)
            days.append(components)
        }
        
        return days
    }
    
    private func toggleDay(_ day: DateComponents) {
        if isSelected(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    private func isSelected(_ day: DateComponents) -> Bool {
        return selectedDays.contains(day)
    }
    
    private func isOutsideMonth(_ day: DateComponents) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let firstOfMonth = calendar.date(from: components)!
        let date = calendar.date(from: day)!
        return calendar.component(.month, from: date) != calendar.component(.month, from: firstOfMonth)
    }
    
    private func saveData(selectedServices: Set<SurgeryService>) {
        guard let selectedHospital = selectedHospital, let selectedPosition = selectedPosition else {
            return
        }
        
        guard !selectedDays.isEmpty else {
            return
        }
        
        guard let currentUserUID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUserUID)
        
        userRef.getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                print("Document does not exist")
                return
            }
            
            let data = document.data()
            
            var existingSelectedServices: Set<SurgeryService> = []
            if let existingServiceNames = data?["selectedSurgeryServices"] as? [String] {
                existingSelectedServices = Set(existingServiceNames.map { SurgeryService(name: $0) })
            }
            
            let updatedSelectedServices = existingSelectedServices.union(selectedServices)
            
            let selectedServiceNames = updatedSelectedServices.map { $0.name }
            
            let selectedDaysArray = selectedDays.compactMap { components -> Int? in
                let calendar = Calendar.current
                guard let date = calendar.date(from: components) else {
                    return nil
                }
                return calendar.component(.day, from: date)
            }
            
            let dataToUpdate: [String: Any] = [
                "hospitalLocation": selectedHospital.name,
                "position": selectedPosition,
                "selectedDays": selectedDaysArray,
                "selectedSurgeryServices": selectedServiceNames
            ]
            
            userRef.setData(dataToUpdate, merge: true) { error in
                if let error = error {
                    print("Error saving data to Firestore: \(error.localizedDescription)")
                } else {
                    print("Data saved successfully to Firestore")
                    navigateToSessionView = true
                }
            }
        }
    }
}

struct CalendarSelectionView_Previews: PreviewProvider {

    static var previews: some View {
        CalendarSelectionView(selectedHospital: .constant(nil), selectedPosition: .constant(nil), selectedServices: .constant([]))
    }
}

///////////// sessionView data


struct BlinkingBar: View {
    @State private var isBlinking = false
    
    var body: some View {
        LinearGradient(gradient: Gradient(stops: [
            .init(color: Color.green.opacity(0.1), location: 0),
            .init(color: Color.green.opacity(0.2), location: 0.5),
            .init(color: Color.green.opacity(0.1), location: 1)
        ]), startPoint: .leading, endPoint: .trailing)
        .frame(height: 2)
        .opacity(isBlinking ? 1 : 0)
        .animation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        )
        .onAppear() {
            isBlinking.toggle()
        }
    }
}

struct SessionView: View {
    @SceneStorage("savedSessionsData") private var savedSessionsData: Data?
    @ObservedObject var sessionViewModel: SessionViewModel
    let selectedHospital: Hospital
    let selectedServices: [String]
    
    var body: some View {
        VStack {
            CustomNavigationBar()
                .padding(.bottom, 8) // Reduced padding to make header smaller
            
            List {
                ForEach(Array(sessionViewModel.sessions.enumerated()), id: \.1.id) { index, session in
                    let user = sessionViewModel.users[session.userID]
                    
                    if index == 0 {
                        Section(header: BlinkingBar().padding(.top, 10)) {
                            SessionDataRow(session: session, isMySession: true, user: user)
                        }
                    } else {
                        SessionDataRow(session: session, isMySession: false, user: user)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .background(Color(red: 255/255, green: 248/255, blue: 230/255))
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackButton())
        .onAppear {
            sessionViewModel.fetchSessions(forHospital: selectedHospital, selectedServices: selectedServices)
        }
    }
}


struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
                .imageScale(.large)
        }
        .padding(.leading, 16) // Adjust leading padding as needed
        .padding(.top, 8) // Standard top padding
        .offset(y: -10) // Negative offset to move button higher
    }
}

struct CustomNavigationBar: View {
    var body: some View {
        HStack {
            Text("Look who's working near you today")
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

    }
}


struct SessionDataRow: View {
    let session: Session
    let isMySession: Bool
    let user: User?
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                if let imageUrl = user?.profileImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(isMySession ? .blue : .gray)
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(isMySession ? .blue : .gray)
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(isMySession ? .blue : .gray)
                }
            }
            .padding(.trailing, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                if let fullname = user?.fullname {
                    Text(fullname)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text("Hospital Location: \(session.hospitalLocation)")
                    .foregroundColor(.white)
                Text("Position: \(session.position)")
                    .foregroundColor(.white)
                Text("Selected Days: \(formatSelectedDays(session.selectedDays))")
                    .foregroundColor(.white)
                Text("Services: \(session.selectedServices.joined(separator: ", "))")
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(isMySession ? Color.blue.opacity(0.7) : Color.black)
        .cornerRadius(10)
        .padding(.horizontal)
        .listRowInsets(EdgeInsets())
    }
    
    private func formatSelectedDays(_ selectedDays: [Int]) -> String {
        guard !selectedDays.isEmpty else {
            return "No days selected"
        }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        
        var formattedDays = ""
        var currentRange: ClosedRange<Int>?
        
        for day in selectedDays.sorted() {
            let components = DateComponents(calendar: calendar, year: currentYear, month: currentMonth, day: day)
            guard let date = calendar.date(from: components) else {
                continue
            }
            
            let monthString = monthFormatter.string(from: date)
            
            if let range = currentRange {
                if day == range.upperBound + 1 {
                    currentRange = range.lowerBound...day
                } else {
                    formattedDays += formatRange(range, monthString: monthString)
                    currentRange = day...day
                }
            } else {
                currentRange = day...day
            }
        }
        
        if let range = currentRange {
            formattedDays += formatRange(range, monthString: monthFormatter.string(from: calendar.date(from: DateComponents(calendar: calendar, year: currentYear, month: currentMonth, day: range.lowerBound))!))
        }
        
        return formattedDays
    }
    
    private func formatRange(_ range: ClosedRange<Int>, monthString: String) -> String {
        if range.lowerBound == range.upperBound {
            return "\(range.lowerBound) \(monthString)"
        } else {
            return "\(range.lowerBound)-\(range.upperBound) \(monthString)"
        }
    }
}


class SessionViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var users: [String: User] = [:] // Dictionary to store user data
    private var listener: ListenerRegistration?
    private var userListener: ListenerRegistration?
    
    func fetchSessions(forHospital hospital: Hospital, selectedServices: [String]) {
        let db = Firestore.firestore()
        
        // Fetch current user's session
        if let currentUserUID = Auth.auth().currentUser?.uid {
            var query = db.collection("users")
                .whereField("hospitalLocation", isEqualTo: hospital.name)
                .whereField("uid", isEqualTo: currentUserUID)
            
            listener = query.addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error retrieving sessions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents in users collection")
                    return
                }
                
                self.sessions = documents.compactMap { document in
                    let data = document.data()
                    guard let hospitalLocation = data["hospitalLocation"] as? String,
                          let position = data["position"] as? String,
                          let selectedDays = data["selectedDays"] as? [Int],
                          let selectedServices = data["selectedSurgeryServices"] as? [String] else {
                        return nil
                    }
                    
                    return Session(id: document.documentID, userID: document.documentID, hospitalLocation: hospitalLocation, position: position, selectedDays: selectedDays, selectedServices: selectedServices)
                }
                
                let userIds = self.sessions.map { $0.userID }
                self.fetchUsers(userIds: userIds)
            }
        }
        
        // Fetch sessions with the same 'Services' selection
        var serviceQuery = db.collection("users")
            .whereField("hospitalLocation", isEqualTo: hospital.name)
        
        if let currentUserUID = Auth.auth().currentUser?.uid {
            db.collection("users").document(currentUserUID).getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                if let document = document, document.exists {
                    if let currentUserSurgeryService = document.data()?["selectedSurgeryServices"] as? [String], let firstService = currentUserSurgeryService.first {
                        serviceQuery = serviceQuery.whereField("selectedSurgeryServices", arrayContains: firstService)
                        
                        self.listener = serviceQuery.addSnapshotListener { [weak self] querySnapshot, error in
                            guard let self = self else { return }
                            
                            if let error = error {
                                print("Error retrieving sessions: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let documents = querySnapshot?.documents else {
                                print("No documents in users collection")
                                return
                            }
                            
                            let additionalSessions = documents.compactMap { document -> Session? in
                                let data = document.data()
                                guard let hospitalLocation = data["hospitalLocation"] as? String,
                                      let position = data["position"] as? String,
                                      let selectedDays = data["selectedDays"] as? [Int],
                                      let selectedServices = data["selectedSurgeryServices"] as? [String] else {
                                    return nil
                                }
                                return Session(id: document.documentID, userID: document.documentID, hospitalLocation: hospitalLocation, position: position, selectedDays: selectedDays, selectedServices: selectedServices)
                            }
                            
                            self.sessions.append(contentsOf: additionalSessions)
                            
                            if let mySessionIndex = self.sessions.firstIndex(where: { $0.userID == currentUserUID }),
                               mySessionIndex > 0 {
                                self.sessions.swapAt(0, mySessionIndex)
                            }
                            
                            let userIds = self.sessions.map { $0.userID }
                            self.fetchUsers(userIds: userIds)
                        }
                    }
                }
            }
        }
    }
    
    private func fetchUsers(userIds: [String]) {
        let db = Firestore.firestore()
        
        for userId in userIds {
            db.collection("users").document(userId).getDocument { [weak self] document, error in
                guard let self = self else { return }
                
                if let document = document, document.exists {
                    if let userData = document.data() {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: userData)
                            let user = try JSONDecoder().decode(User.self, from: jsonData)
                            DispatchQueue.main.async {
                                self.users[userId] = user
                            }
                        } catch {
                            print("Error decoding user data: \(error)")
                        }
                    }
                } else {
                    print("User does not exist")
                }
            }
        }
    }
}
