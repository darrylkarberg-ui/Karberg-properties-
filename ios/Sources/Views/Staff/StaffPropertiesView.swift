import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

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
      properties = try snap.documents.map { try $0.data(as: Property.self) }
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
    guard let propertyId = property.docId else { return }
    isLoading = true
    defer { isLoading = false }
    error = nil

    do {
      let snap = try await FirebaseService.shared.db.collection("units")
        .whereField("propertyId", isEqualTo: propertyId)
        .order(by: "label")
        .getDocuments()
      units = try snap.documents.map { try $0.data(as: Unit.self) }
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
    guard let unitId = unit.id else { return }
    isLoading = true
    defer { isLoading = false }
    error = nil

    do {
      let snap = try await FirebaseService.shared.db.collection("leases")
        .whereField("unitId", isEqualTo: unitId)
        .limit(to: 1)
        .getDocuments()
      lease = try snap.documents.first?.data(as: Lease.self)

      if let leaseId = lease?.docId {
        docs = try await FirebaseService.shared.listLeaseDocs(leaseId: leaseId)
      } else {
        docs = []
      }
    } catch {
      self.error = error.localizedDescription
    }
  }
}
