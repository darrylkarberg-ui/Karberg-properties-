import SwiftUI

struct StaffTabView: View {
  var body: some View {
    TabView {
      NavigationStack {
        StaffDashboardView()
      }
      .tabItem { Label("Dashboard", systemImage: "chart.bar") }

      NavigationStack {
        StaffPropertiesView()
      }
      .tabItem { Label("Properties", systemImage: "building.2") }

      NavigationStack {
        TicketListView(mode: .staff)
      }
      .tabItem { Label("Tickets", systemImage: "wrench.and.screwdriver") }
    }
  }
}
