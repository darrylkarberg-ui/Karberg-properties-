import SwiftUI

struct LeaseDocView: View {
  let doc: LeaseDoc

  @State private var url: URL?
  @State private var isLoading = false
  @State private var error: String?

  var body: some View {
    Group {
      if let url {
        ShareLink(item: url) {
          Label("Share / Download", systemImage: "square.and.arrow.up")
        }
        .padding(.bottom, 12)

        Text(url.absoluteString)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
      } else if isLoading {
        ProgressView("Loading…")
      } else {
        Text(error ?? "Unable to load document")
          .foregroundStyle(.red)
      }
    }
    .padding()
    .navigationTitle(doc.filename)
    .task { await load() }
  }

  private func load() async {
    isLoading = true
    defer { isLoading = false }
    do {
      url = try await FirebaseService.shared.downloadURL(for: doc.storagePath)
    } catch {
      self.error = error.localizedDescription
    }
  }
}
