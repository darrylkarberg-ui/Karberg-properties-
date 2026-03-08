import Foundation
import FirebaseAuth

@MainActor
final class SessionStore: ObservableObject {
  @Published var user: User?
  @Published var profile: AppUser?
  @Published var isLoading: Bool = true
  @Published var errorMessage: String?

  private var authListener: AuthStateDidChangeListenerHandle?

  func start() {
    if authListener != nil { return }
    authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      Task { @MainActor in
        self?.user = user
        await self?.loadProfile()
      }
    }
  }

  func stop() {
    if let authListener {
      Auth.auth().removeStateDidChangeListener(authListener)
      self.authListener = nil
    }
  }

  func loadProfile() async {
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil

    guard let uid = user?.uid else {
      profile = nil
      return
    }

    do {
      profile = try await FirebaseService.shared.fetchUser(uid: uid)
    } catch {
      errorMessage = error.localizedDescription
      profile = nil
    }
  }

  func signOut() {
    do {
      try Auth.auth().signOut()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
