import SwiftUI

struct TenantTabView: View {
  var body: some View {
    TabView {
      NavigationStack {
        TenantHomeView()
      }
      .tabItem { Label("My Lease", systemImage: "doc.text") }

      NavigationStack {
        TicketListView(mode: .tenant)
      }
      .tabItem { Label("Tickets", systemImage: "wrench") }
    }
  }
}
