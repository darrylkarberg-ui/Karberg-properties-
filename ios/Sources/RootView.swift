import SwiftUI

struct RootView: View {
  var body: some View {
    NavigationStack {
      VStack(spacing: 12) {
        Text("Karberg Properties")
          .font(.title.bold())

        Text("Bootstrap build")
          .foregroundStyle(.secondary)

        // TODO: Auth gate (login / signup)
        // TODO: Role routing (staff vs tenant)
      }
      .padding()
    }
  }
}

#Preview {
  RootView()
}
