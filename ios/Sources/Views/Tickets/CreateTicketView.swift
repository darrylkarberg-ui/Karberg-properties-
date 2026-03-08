import SwiftUI
import PhotosUI
import FirebaseAuth

struct CreateTicketView: View {
  @EnvironmentObject var session: SessionStore
  @Environment(\.dismiss) private var dismiss

  @State private var category: TicketCategory = .plumbing
  @State private var description: String = ""

  @State private var pickerItems: [PhotosPickerItem] = []
  @State private var isSubmitting = false
  @State private var error: String?

  var body: some View {
    Form {
      Section("Category") {
        Picker("Category", selection: $category) {
          ForEach(TicketCategory.allCases, id: \.self) { c in
            Text(c.rawValue.capitalized).tag(c)
          }
        }
      }

      Section("Description") {
        TextField("What’s the issue?", text: $description, axis: .vertical)
          .lineLimit(4...10)
      }

      Section("Photos") {
        PhotosPicker(selection: $pickerItems, maxSelectionCount: 6, matching: .images) {
          Label("Select photos", systemImage: "photo.on.rectangle")
        }
        Text("Selected: \(pickerItems.count)")
          .foregroundStyle(.secondary)
      }

      if let error {
        Section { Text(error).foregroundStyle(.red) }
      }

      Section {
        Button {
          Task { await submit() }
        } label: {
          HStack {
            Spacer()
            if isSubmitting { ProgressView().padding(.trailing, 8) }
            Text("Submit")
            Spacer()
          }
        }
        .disabled(isSubmitting || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .navigationTitle("Report issue")
  }

  private func submit() async {
    guard let user = Auth.auth().currentUser else { return }
    guard let leaseId = session.profile?.leaseId else { return }

    isSubmitting = true
    defer { isSubmitting = false }
    error = nil

    do {
      let photos = try await uploadSelectedPhotos(uid: user.uid)
      try await FirebaseService.shared.createTicket(
        leaseId: leaseId,
        createdByUid: user.uid,
        category: category,
        description: description.trimmingCharacters(in: .whitespacesAndNewlines),
        photos: photos
      )
      dismiss()
    } catch {
      self.error = error.localizedDescription
    }
  }

  private func uploadSelectedPhotos(uid: String) async throws -> [TicketPhoto] {
    guard !pickerItems.isEmpty else { return [] }

    return try await withThrowingTaskGroup(of: TicketPhoto.self) { group in
      for item in pickerItems {
        group.addTask {
          guard let data = try await item.loadTransferable(type: Data.self) else {
            throw NSError(domain: "KarbergProperties", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to read image"]) 
          }
          // Store raw bytes as JPEG; Photos may provide HEIC/PNG. For MVP, upload as-is but label jpeg.
          let filename = "\(UUID().uuidString).jpg"
          let storagePath = "tickets/\(uid)/\(filename)"
          try await FirebaseService.shared.uploadJPEG(data: data, storagePath: storagePath)
          return TicketPhoto(storagePath: storagePath, contentType: "image/jpeg", filename: filename)
        }
      }

      var out: [TicketPhoto] = []
      for try await p in group { out.append(p) }
      return out
    }
  }
}
