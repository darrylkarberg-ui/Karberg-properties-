import Foundation
import FirebaseFirestore

// MARK: - Domain

enum UserRole: String, CaseIterable {
  case landlord
  case manager
  case tenant

  var isStaff: Bool { self == .landlord || self == .manager }
}

enum TicketStatus: String, CaseIterable {
  case submitted
  case acknowledged
  case in_progress
  case done
  case rejected
}

enum TicketCategory: String, CaseIterable {
  case plumbing
  case electrical
  case heating
  case appliances
  case pests
  case other
}

// MARK: - Models (manual Firestore mapping; avoids FirebaseFirestoreSwift)

struct AppUser {
  var role: UserRole
  var email: String
  var displayName: String?
  var leaseId: String?

  init(role: UserRole, email: String, displayName: String? = nil, leaseId: String? = nil) {
    self.role = role
    self.email = email
    self.displayName = displayName
    self.leaseId = leaseId
  }

  init?(data: [String: Any]) {
    guard let roleStr = data["role"] as? String,
          let role = UserRole(rawValue: roleStr),
          let email = data["email"] as? String
    else { return nil }

    self.role = role
    self.email = email
    self.displayName = data["displayName"] as? String
    self.leaseId = data["leaseId"] as? String
  }

  func toData() -> [String: Any] {
    var out: [String: Any] = [
      "role": role.rawValue,
      "email": email,
      "updatedAt": FieldValue.serverTimestamp()
    ]
    if let displayName { out["displayName"] = displayName }
    if let leaseId { out["leaseId"] = leaseId }
    if out["createdAt"] == nil { out["createdAt"] = FieldValue.serverTimestamp() }
    return out
  }
}

struct Property: Identifiable {
  var id: String
  var name: String
  var address: String
  var notes: String?

  init?(id: String, data: [String: Any]) {
    guard let name = data["name"] as? String,
          let address = data["address"] as? String
    else { return nil }
    self.id = id
    self.name = name
    self.address = address
    self.notes = data["notes"] as? String
  }
}

struct Unit: Identifiable {
  var id: String
  var propertyId: String
  var label: String
  var notes: String?

  init?(id: String, data: [String: Any]) {
    guard let propertyId = data["propertyId"] as? String,
          let label = data["label"] as? String
    else { return nil }
    self.id = id
    self.propertyId = propertyId
    self.label = label
    self.notes = data["notes"] as? String
  }
}

struct Lease: Identifiable {
  var id: String
  var unitId: String
  var tenantUid: String?
  var tenantEmail: String?
  var rentAmountEur: Int
  var dueDay: Int

  init?(id: String, data: [String: Any]) {
    guard let unitId = data["unitId"] as? String,
          let rentAmountEur = data["rentAmountEur"] as? Int,
          let dueDay = data["dueDay"] as? Int
    else { return nil }
    self.id = id
    self.unitId = unitId
    self.rentAmountEur = rentAmountEur
    self.dueDay = dueDay
    self.tenantUid = data["tenantUid"] as? String
    self.tenantEmail = data["tenantEmail"] as? String
  }
}

struct LeaseDoc: Identifiable {
  var id: String
  var leaseId: String
  var filename: String
  var storagePath: String
  var contentType: String

  init?(id: String, data: [String: Any]) {
    guard let leaseId = data["leaseId"] as? String,
          let filename = data["filename"] as? String,
          let storagePath = data["storagePath"] as? String
    else { return nil }
    self.id = id
    self.leaseId = leaseId
    self.filename = filename
    self.storagePath = storagePath
    self.contentType = (data["contentType"] as? String) ?? "application/pdf"
  }
}

struct TicketPhoto {
  var storagePath: String
  var contentType: String
  var filename: String

  // Used when creating a new ticket locally (before saving to Firestore).
  init(storagePath: String, contentType: String, filename: String) {
    self.storagePath = storagePath
    self.contentType = contentType
    self.filename = filename
  }

  // Used when decoding a ticket coming back from Firestore.
  init?(data: [String: Any]) {
    guard let storagePath = data["storagePath"] as? String,
          let contentType = data["contentType"] as? String,
          let filename = data["filename"] as? String
    else { return nil }
    self.storagePath = storagePath
    self.contentType = contentType
    self.filename = filename
  }

  func toData() -> [String: Any] {
    [
      "storagePath": storagePath,
      "contentType": contentType,
      "filename": filename
    ]
  }
}

struct Ticket: Identifiable {
  var id: String
  var leaseId: String
  var category: String
  var description: String
  var status: String
  var photos: [TicketPhoto]
  var staffNote: String?
  var createdByUid: String

  init?(id: String, data: [String: Any]) {
    guard let leaseId = data["leaseId"] as? String,
          let category = data["category"] as? String,
          let description = data["description"] as? String,
          let status = data["status"] as? String,
          let createdByUid = data["createdByUid"] as? String
    else { return nil }

    self.id = id
    self.leaseId = leaseId
    self.category = category
    self.description = description
    self.status = status
    self.createdByUid = createdByUid
    self.staffNote = data["staffNote"] as? String

    let arr = (data["photos"] as? [[String: Any]]) ?? []
    self.photos = arr.compactMap { TicketPhoto(data: $0) }
  }

  static func createData(leaseId: String, category: TicketCategory, description: String, photos: [TicketPhoto], createdByUid: String) -> [String: Any] {
    [
      "leaseId": leaseId,
      "category": category.rawValue,
      "description": description,
      "status": TicketStatus.submitted.rawValue,
      "photos": photos.map { $0.toData() },
      "createdByUid": createdByUid,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp()
    ]
  }
}

struct LeaseCode {
  var leaseId: String
  var active: Bool
  var redeemedByUid: String?

  init?(data: [String: Any]) {
    guard let leaseId = data["leaseId"] as? String,
          let active = data["active"] as? Bool
    else { return nil }
    self.leaseId = leaseId
    self.active = active
    self.redeemedByUid = data["redeemedByUid"] as? String
  }
}
