import SwiftUI

struct StaffDashboardView: View {
  @EnvironmentObject var session: SessionStore

  @State private var openTickets: [Ticket] = []
  @State private var isLoading = false
  @State private var error: String?

  var body: some View {
    List {
      Section("Open tickets") {
        if openTickets.isEmpty {
          Text("No open tickets")
            .foregroundStyle(.secondary)
        } else {
          ForEach(openTickets) { t in
            NavigationLink {
              TicketDetailView(ticket: t, mode: .staff)
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                Text(t.category.capitalized)
                  .font(.headline)
                Text(t.description)
                  .lineLimit(2)
                  .foregroundStyle(.secondary)
                Text(t.status.replacingOccurrences(of: "_", with: " ").capitalized)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
        }
      }

      if let error {
        Section { Text(error).foregroundStyle(.red) }
      }
    }
    .navigationTitle("Dashboard")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Sign out") { session.signOut() }
      }
    }
    .overlay { if isLoading { ProgressView() } }
    .task { await load() }
    .refreshable { await load() }
  }

  private func load() async {
    isLoading = true
    defer { isLoading = false }
    error = nil

    do {
      openTickets = try await FirebaseService.shared.listOpenTicketsForStaff()
    } catch {
      self.error = error.localizedDescription
    }
  }
}
