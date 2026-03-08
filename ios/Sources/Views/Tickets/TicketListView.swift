import SwiftUI

struct TicketListView: View {
  let mode: Mode

  @EnvironmentObject var session: SessionStore

  @State private var tickets: [Ticket] = []
  @State private var isLoading = false
  @State private var error: String?

  enum Mode {
    case tenant
    case staff
  }

  var body: some View {
    List {
      if tickets.isEmpty {
        Text("No tickets")
          .foregroundStyle(.secondary)
      } else {
        ForEach(tickets) { t in
          NavigationLink {
            TicketDetailView(ticket: t, mode: mode)
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

      if let error {
        Text(error).foregroundStyle(.red)
      }
    }
    .navigationTitle(mode == .tenant ? "My Tickets" : "Tickets")
    .toolbar {
      if mode == .tenant {
        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink {
            CreateTicketView()
          } label: {
            Label("Report", systemImage: "plus")
          }
        }
      }
    }
    .overlay {
      if isLoading { ProgressView() }
    }
    .task { await load() }
    .refreshable { await load() }
  }

  private func load() async {
    isLoading = true
    defer { isLoading = false }
    error = nil

    do {
      switch mode {
      case .tenant:
        guard let leaseId = session.profile?.leaseId else { return }
        tickets = try await FirebaseService.shared.listTicketsForLease(leaseId: leaseId)
      case .staff:
        tickets = try await FirebaseService.shared.listOpenTicketsForStaff()
      }
    } catch {
      self.error = error.localizedDescription
    }
  }
}
