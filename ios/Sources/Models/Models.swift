import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Domain

enum UserRole: String, Codable, CaseIterable {
  case landlord
  case manager
  case tenant

  var isStaff: Bool { self == .landlord || self == .manager }
}

enum TicketStatus: String, Codable, CaseIterable {
  case submitted
  case acknowledged
  case in_progress
  case done
  case rejected
}

enum TicketCategory: String, Codable, CaseIterable {
  case plumbing
  case electrical
  case heating
  case appliances
  case pests
  case other
}

struct AppUser: Codable {
  var role: UserRole
  var email: String
  var displayName: String?
  var leaseId: String?
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?
}

// MARK: - Entities

struct Property: Codable, Identifiable {
  @DocumentID var docId: String?
  var id: String { docId ?? UUID().uuidString }

  var name: String
  var address: String
  var notes: String?
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?
}

struct Unit: Codable, Identifiable {
  @DocumentID var docId: String?
  var id: String { docId ?? UUID().uuidString }

  var propertyId: String
  var label: String
  var notes: String?
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?
}

struct Lease: Codable, Identifiable {
  @DocumentID var docId: String?
  var id: String { docId ?? UUID().uuidString }

  var unitId: String
  var tenantUid: String?
  var tenantEmail: String?
  var rentAmountEur: Int
  var dueDay: Int
  var startDate: Timestamp?
  var endDate: Timestamp?
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?
}

struct LeaseDoc: Codable, Identifiable {
  @DocumentID var docId: String?
  var id: String { docId ?? UUID().uuidString }

  var leaseId: String
  var filename: String
  var storagePath: String
  var contentType: String
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?
}

struct RentEntry: Codable, Identifiable {
  @DocumentID var docId: String?
  var id: String { docId ?? UUID().uuidString }

  var leaseId: String
  var month: String // YYYY-MM
  var status: String // paid|unpaid
  var paidAt: Timestamp?
  var note: String?
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?
}

struct TicketPhoto: Codable {
  var storagePath: String
  var contentType: String
  var filename: String
}

struct Ticket: Codable, Identifiable {
  @DocumentID var docId: String?
  var id: String { docId ?? UUID().uuidString }

  var leaseId: String
  var category: String
  var description: String
  var status: String
  var photos: [TicketPhoto]
  var staffNote: String?
  var createdByUid: String
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?
}

struct LeaseCode: Codable {
  var leaseId: String
  var codeHash: String?
  var active: Bool
  var redeemedByUid: String?
  var redeemedAt: Timestamp?
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?
}
