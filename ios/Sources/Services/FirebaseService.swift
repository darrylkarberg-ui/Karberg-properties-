import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

final class FirebaseService {
  static let shared = FirebaseService()

  let auth = Auth.auth()
  let db = Firestore.firestore()
  let storage = Storage.storage()

  private init() {}

  // MARK: - User

  func userDocRef(uid: String) -> DocumentReference {
    db.collection("users").document(uid)
  }

  func fetchUser(uid: String) async throws -> AppUser? {
    let snap = try await userDocRef(uid: uid).getDocument()
    guard snap.exists else { return nil }
    return try snap.data(as: AppUser.self)
  }

  func upsertUser(uid: String, user: AppUser) async throws {
    try userDocRef(uid: uid).setData(from: user, merge: true)
  }

  // MARK: - Lease

  func fetchLease(leaseId: String) async throws -> Lease? {
    let snap = try await db.collection("leases").document(leaseId).getDocument()
    guard snap.exists else { return nil }
    return try snap.data(as: Lease.self)
  }

  func listLeaseDocs(leaseId: String) async throws -> [LeaseDoc] {
    let snap = try await db.collection("leaseDocs")
      .whereField("leaseId", isEqualTo: leaseId)
      .getDocuments()

    return try snap.documents.map { try $0.data(as: LeaseDoc.self) }
  }

  // MARK: - Tickets

  func listTicketsForLease(leaseId: String) async throws -> [Ticket] {
    let snap = try await db.collection("tickets")
      .whereField("leaseId", isEqualTo: leaseId)
      .order(by: "createdAt", descending: true)
      .getDocuments()
    return try snap.documents.map { try $0.data(as: Ticket.self) }
  }

  func listOpenTicketsForStaff(limit: Int = 50) async throws -> [Ticket] {
    let snap = try await db.collection("tickets")
      .whereField("status", in: [TicketStatus.submitted.rawValue, TicketStatus.acknowledged.rawValue, TicketStatus.in_progress.rawValue])
      .order(by: "createdAt", descending: true)
      .limit(to: limit)
      .getDocuments()
    return try snap.documents.map { try $0.data(as: Ticket.self) }
  }

  func updateTicketStatus(ticketId: String, status: TicketStatus, staffNote: String?) async throws {
    var data: [String: Any] = [
      "status": status.rawValue,
      "updatedAt": FieldValue.serverTimestamp()
    ]
    if let staffNote { data["staffNote"] = staffNote }
    try await db.collection("tickets").document(ticketId).updateData(data)
  }

  func createTicket(leaseId: String, createdByUid: String, category: TicketCategory, description: String, photos: [TicketPhoto]) async throws {
    let doc = db.collection("tickets").document()
    let ticket = Ticket(
      docId: doc.documentID,
      leaseId: leaseId,
      category: category.rawValue,
      description: description,
      status: TicketStatus.submitted.rawValue,
      photos: photos,
      staffNote: nil,
      createdByUid: createdByUid,
      createdAt: nil,
      updatedAt: nil
    )
    try doc.setData(from: ticket, merge: true)
  }

  // MARK: - Storage

  func uploadJPEG(data: Data, storagePath: String) async throws {
    let ref = storage.reference(withPath: storagePath)
    let meta = StorageMetadata()
    meta.contentType = "image/jpeg"
    _ = try await ref.putDataAsync(data, metadata: meta)
  }

  func downloadURL(for storagePath: String) async throws -> URL {
    try await storage.reference(withPath: storagePath).downloadURL()
  }

  // MARK: - Lease Codes (redeem)

  /// Redeems a lease code that is stored as a document id under `leaseCodes/{code}`.
  ///
  /// NOTE: Requires Firestore rules to allow `get` for this doc id.
  func redeemLeaseCode(code: String, uid: String, email: String) async throws -> String {
    let codeRef = db.collection("leaseCodes").document(code)
    let snap = try await codeRef.getDocument()
    guard snap.exists else {
      throw NSError(domain: "KarbergProperties", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid lease code"])
    }
    let leaseCode = try snap.data(as: LeaseCode.self)
    guard leaseCode.active else {
      throw NSError(domain: "KarbergProperties", code: 400, userInfo: [NSLocalizedDescriptionKey: "Lease code is inactive"])
    }
    if let redeemedBy = leaseCode.redeemedByUid, !redeemedBy.isEmpty {
      throw NSError(domain: "KarbergProperties", code: 409, userInfo: [NSLocalizedDescriptionKey: "Lease code already redeemed"])
    }

    // Update user profile with leaseId
    try await upsertUser(uid: uid, user: AppUser(role: .tenant, email: email, displayName: nil, leaseId: leaseCode.leaseId, createdAt: nil, updatedAt: nil))

    // Best effort mark code as redeemed (may require rule support)
    do {
      try await codeRef.updateData([
        "redeemedByUid": uid,
        "redeemedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
      ])
    } catch {
      // Ignore if rules don't allow it; lease linking still works via user profile.
    }

    // Best effort: set tenantUid/email on lease (staff-only in rules; ignore failure)
    do {
      try await db.collection("leases").document(leaseCode.leaseId).updateData([
        "tenantUid": uid,
        "tenantEmail": email,
        "updatedAt": FieldValue.serverTimestamp()
      ])
    } catch {
      // ignore
    }

    return leaseCode.leaseId
  }
}
