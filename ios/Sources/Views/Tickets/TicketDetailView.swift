import SwiftUI

struct TicketDetailView: View {
  let ticket: Ticket
  let mode: TicketListView.Mode

  @EnvironmentObject var session: SessionStore

  @State private var photosURLs: [URL] = []
  @State private var isLoadingPhotos = false
  @State private var updating = false
  @State private var error: String?

  @State private var newStatus: TicketStatus = .submitted
  @State private var staffNote: String = ""

  var body: some View {
    Form {
      Section("Issue") {
        LabeledContent("Category", value: ticket.category.capitalized)
        LabeledContent("Status", value: ticket.status.replacingOccurrences(of: "_", with: " ").capitalized)
        Text(ticket.description)
      }

      if !ticket.photos.isEmpty {
        Section("Photos") {
          if isLoadingPhotos {
            ProgressView("Loading…")
          } else {
            ForEach(Array(photosURLs.enumerated()), id: \.offset) { _, url in
              Text(url.lastPathComponent)
                .font(.footnote)
              ShareLink(item: url) {
                Label("Share", systemImage: "square.and.arrow.up")
              }
            }
          }
        }
      }

      if mode == .staff {
        Section("Update") {
          Picker("Status", selection: $newStatus) {
            ForEach(TicketStatus.allCases, id: \.self) { s in
              Text(s.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                .tag(s)
            }
          }

          TextField("Staff note (optional)", text: $staffNote, axis: .vertical)
            .lineLimit(3...8)

          Button {
            Task { await save() }
          } label: {
            if updating { ProgressView() } else { Text("Save") }
          }
          .disabled(updating)
        }
      }

      if let error {
        Section { Text(error).foregroundStyle(.red) }
      }
    }
    .navigationTitle("Ticket")
    .task {
      newStatus = TicketStatus(rawValue: ticket.status) ?? .submitted
      staffNote = ticket.staffNote ?? ""
      await loadPhotos()
    }
  }

  private func loadPhotos() async {
    guard !ticket.photos.isEmpty else { return }
    isLoadingPhotos = true
    defer { isLoadingPhotos = false }
    do {
      photosURLs = try await withThrowingTaskGroup(of: URL.self) { group in
        for p in ticket.photos {
          group.addTask { try await FirebaseService.shared.downloadURL(for: p.storagePath) }
        }
        var urls: [URL] = []
        for try await url in group { urls.append(url) }
        return urls
      }
    } catch {
      self.error = error.localizedDescription
    }
  }

  private func save() async {
    guard let ticketId = ticket.docId else { return }
    updating = true
    defer { updating = false }
    error = nil

    do {
      try await FirebaseService.shared.updateTicketStatus(ticketId: ticketId, status: newStatus, staffNote: staffNote.isEmpty ? nil : staffNote)
    } catch {
      self.error = error.localizedDescription
    }
  }
}
