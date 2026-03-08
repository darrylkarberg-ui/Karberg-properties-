import Foundation
import FirebaseAuth
import FirebaseFirestore
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
    guard let data = snap.data() else { return nil }
    return AppUser(data: data)
  }

  func upsertUser(uid: String, user: AppUser) async throws {
    try await userDocRef(uid: uid).setData(user.toData(), merge: true)
  }

  // MARK: - Lease

  func fetchLease(leaseId: String) async throws -> Lease? {
    let snap = try await db.collection("leases").document(leaseId).getDocument()
    guard let data = snap.data() else { return nil }
    return Lease(id: snap.documentID, data: data)
  }

  func listLeaseDocs(leaseId: String) async throws -> [LeaseDoc] {
    let snap = try await db.collection("leaseDocs")
      .whereField("leaseId", isEqualTo: leaseId)
      .getDocuments()

    return snap.documents.compactMap { d in
      LeaseDoc(id: d.documentID, data: d.data())
    }
  }

  // MARK: - Tickets

  func listTicketsForLease(leaseId: String) async throws -> [Ticket] {
    let snap = try await db.collection("tickets")
      .whereField("leaseId", isEqualTo: leaseId)
      .order(by: "createdAt", descending: true)
      .getDocuments()

    return snap.documents.compactMap { Ticket(id: $0.documentID, data: $0.data()) }
  }

  func listOpenTicketsForStaff(limit: Int = 50) async throws -> [Ticket] {
    let snap = try await db.collection("tickets")
      .whereField("status", in: [TicketStatus.submitted.rawValue, TicketStatus.acknowledged.rawValue, TicketStatus.in_progress.rawValue])
      .order(by: "createdAt", descending: true)
      .limit(to: limit)
      .getDocuments()

    return snap.documents.compactMap { Ticket(id: $0.documentID, data: $0.data()) }
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
    let data = Ticket.createData(
      leaseId: leaseId,
      category: category,
      description: description,
      photos: photos,
      createdByUid: createdByUid
    )
    try await doc.setData(data, merge: true)
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
  func redeemLeaseCode(code: String, uid: String, email: String) async throws -> String {
    let codeRef = db.collection("leaseCodes").document(code)
    let snap = try await codeRef.getDocument()
    guard let data = snap.data(), let leaseCode = LeaseCode(data: data) else {
      throw NSError(domain: "KarbergProperties", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid lease code"])
    }
    guard leaseCode.active else {
      throw NSError(domain: "KarbergProperties", code: 400, userInfo: [NSLocalizedDescriptionKey: "Lease code is inactive"])
    }
    if let redeemedBy = leaseCode.redeemedByUid, !redeemedBy.isEmpty {
      throw NSError(domain: "KarbergProperties", code: 409, userInfo: [NSLocalizedDescriptionKey: "Lease code already redeemed"])
    }

    // Update user profile with leaseId
    try await upsertUser(uid: uid, user: AppUser(role: .tenant, email: email, leaseId: leaseCode.leaseId))

    // Mark code as redeemed (rules should allow this if unredeemed)
    do {
      try await codeRef.updateData([
        "redeemedByUid": uid,
        "redeemedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
      ])
    } catch {
      // ignore
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
