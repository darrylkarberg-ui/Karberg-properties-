import SwiftUI

struct StaffPropertiesView: View {
  @State private var properties: [Property] = []
  @State private var isLoading = false
  @State private var error: String?

  var body: some View {
    List {
      if properties.isEmpty {
        Text("No properties")
          .foregroundStyle(.secondary)
      } else {
        ForEach(properties) { p in
          NavigationLink {
            StaffUnitsView(property: p)
          } label: {
            VStack(alignment: .leading) {
              Text(p.name)
              Text(p.address)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
        }
      }

      if let error {
        Text(error).foregroundStyle(.red)
      }
    }
    .navigationTitle("Properties")
    .overlay { if isLoading { ProgressView() } }
    .task { await load() }
    .refreshable { await load() }
  }

  private func load() async {
    isLoading = true
    defer { isLoading = false }
    error = nil

    do {
      let snap = try await FirebaseService.shared.db.collection("properties").order(by: "name").getDocuments()
      properties = snap.documents.compactMap { d in
        Property(id: d.documentID, data: d.data())
      }
    } catch {
      self.error = error.localizedDescription
    }
  }
}

struct StaffUnitsView: View {
  let property: Property

  @State private var units: [Unit] = []
  @State private var isLoading = false
  @State private var error: String?

  var body: some View {
    List {
      if units.isEmpty {
        Text("No units")
          .foregroundStyle(.secondary)
      } else {
        ForEach(units) { u in
          NavigationLink {
            StaffLeaseView(unit: u)
          } label: {
            Text(u.label)
          }
        }
      }

      if let error {
        Text(error).foregroundStyle(.red)
      }
    }
    .navigationTitle(property.name)
    .overlay { if isLoading { ProgressView() } }
    .task { await load() }
    .refreshable { await load() }
  }

  private func load() async {
    isLoading = true
    defer { isLoading = false }
    error = nil

    do {
      let snap = try await FirebaseService.shared.db.collection("units")
        .whereField("propertyId", isEqualTo: property.id)
        .order(by: "label")
        .getDocuments()
      units = snap.documents.compactMap { d in
        Unit(id: d.documentID, data: d.data())
      }
    } catch {
      self.error = error.localizedDescription
    }
  }
}

struct StaffLeaseView: View {
  let unit: Unit

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
          LabeledContent("Tenant", value: lease.tenantEmail ?? "-")
        } else {
          Text("No lease")
            .foregroundStyle(.secondary)
        }
      }

      Section("Documents") {
        if docs.isEmpty {
          Text("No documents")
            .foregroundStyle(.secondary)
        } else {
          ForEach(docs) { d in
            NavigationLink { LeaseDocView(doc: d) } label: { Text(d.filename) }
          }
        }
      }

      if let error {
        Text(error).foregroundStyle(.red)
      }
    }
    .navigationTitle(unit.label)
    .overlay { if isLoading { ProgressView() } }
    .task { await load() }
    .refreshable { await load() }
  }

  private func load() async {
    isLoading = true
    defer { isLoading = false }
    error = nil

    do {
      let snap = try await FirebaseService.shared.db.collection("leases")
        .whereField("unitId", isEqualTo: unit.id)
        .limit(to: 1)
        .getDocuments()
      if let first = snap.documents.first {
        lease = Lease(id: first.documentID, data: first.data())
      } else {
        lease = nil
      }

      if let lease {
        docs = try await FirebaseService.shared.listLeaseDocs(leaseId: lease.id)
      } else {
        docs = []
      }
    } catch {
      self.error = error.localizedDescription
    }
  }
}
