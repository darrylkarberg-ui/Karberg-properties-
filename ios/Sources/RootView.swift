import SwiftUI

struct RootView: View {
  @StateObject private var session = SessionStore()

  var body: some View {
    Group {
      if session.user == nil {
        AuthView()
      } else if session.isLoading {
        ProgressView("Loading…")
      } else if session.profile == nil {
        NavigationStack {
          OnboardingView()
        }
      } else if let profile = session.profile {
        if profile.role.isStaff {
          StaffTabView()
        } else {
          TenantTabView()
        }
      }
    }
    .environmentObject(session)
    .task { session.start() }
  }
}

#Preview {
  RootView()
}
