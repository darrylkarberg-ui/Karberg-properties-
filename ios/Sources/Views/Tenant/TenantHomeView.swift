import SwiftUI
import FirebaseAuth

struct TenantHomeView: View {
  @EnvironmentObject var session: SessionStore

  @State private var lease: Lease?
  @State private var docs: [LeaseDoc] = []
  @State private var isLoading = false
  @State private var error: String?

  var body: some View {
    List {
      Section("Lease") {
        if let lease {
          LabeledContent("Rent", value: "€\(lease.rentAmountEur)")
          LabeledContent("Due day", value: "\(lease.dueDay)")
          if let unitId = lease.unitId as String? {
            LabeledContent("Unit", value: unitId)
              .foregroundStyle(.secondary)
          }
        } else {
          Text("No lease linked.")
            .foregroundStyle(.secondary)
        }
      }

      Section("Documents") {
        if docs.isEmpty {
          Text("No documents")
            .foregroundStyle(.secondary)
        } else {
          ForEach(docs) { doc in
            NavigationLink {
              LeaseDocView(doc: doc)
            } label: {
              Text(doc.filename)
            }
          }
        }
      }

      if let error {
        Section {
          Text(error).foregroundStyle(.red)
        }
      }
    }
    .navigationTitle("My Lease")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Sign out") { session.signOut() }
      }
    }
    .overlay {
      if isLoading { ProgressView() }
    }
    .task { await load() }
    .refreshable { await load() }
  }

  private func load() async {
    guard let leaseId = session.profile?.leaseId else { return }
    isLoading = true
    defer { isLoading = false }
    error = nil

    do {
      lease = try await FirebaseService.shared.fetchLease(leaseId: leaseId)
      docs = try await FirebaseService.shared.listLeaseDocs(leaseId: leaseId)
    } catch {
      self.error = error.localizedDescription
    }
  }
}
