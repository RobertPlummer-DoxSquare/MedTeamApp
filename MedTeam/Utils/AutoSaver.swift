//
//  AutoSaver.swift
//  MedTeam
//

import SwiftUI

/// Saves profile edits as they happen and briefly shows "Saved".
/// Text fields pass a delay so the write happens once the user pauses typing.
@MainActor
final class AutoSaver: ObservableObject {
    @Published private(set) var showSaved = false
    @Published private(set) var errorMessage: String?

    private var pending: [String: Task<Void, Never>] = [:]
    private var hideTask: Task<Void, Never>?

    func save(_ fields: [String: Any], after delay: Duration = .zero) {
        let key = fields.keys.sorted().joined(separator: ",")
        pending[key]?.cancel()
        pending[key] = Task {
            if delay > .zero {
                try? await Task.sleep(for: delay)
                if Task.isCancelled { return }
            }
            do {
                try await UserService.shared.updateFields(fields)
                errorMessage = nil
                flashSaved()
            } catch {
                errorMessage = "Couldn't save. Check your connection and try again."
            }
        }
    }

    private func flashSaved() {
        showSaved = true
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            if !Task.isCancelled { showSaved = false }
        }
    }
}

/// Shows a small "Saved" (or error) pill at the bottom of the screen.
struct SaveStatusOverlay: ViewModifier {
    @ObservedObject var saver: AutoSaver

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            Group {
                if let error = saver.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color.red))
                } else if saver.showSaved {
                    Label("Saved", systemImage: "checkmark")
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color.nmaPrimary))
                }
            }
            .font(.footnote.weight(.semibold))
            .padding(.bottom, 24)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: saver.showSaved)
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}

extension View {
    func saveStatus(_ saver: AutoSaver) -> some View {
        modifier(SaveStatusOverlay(saver: saver))
    }
}
