import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
  @EnvironmentObject var session: SessionStore

  @State private var role: UserRole = .tenant
  @State private var leaseCode: String = ""
  @State private var busy: Bool = false
  @State private var error: String?

  var body: some View {
    Form {
      Section("Role") {
        Picker("Account type", selection: $role) {
          Text("Tenant").tag(UserRole.tenant)
          Text("Staff (manager)").tag(UserRole.manager)
        }
        .pickerStyle(.segmented)
      }

      if role == .tenant {
        Section("Lease Code") {
          TextField("Enter lease code", text: $leaseCode)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

          Text("You’ll receive this code from your landlord/manager.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      } else {
        Section {
          Text("Staff accounts can browse properties, manage leases and tickets.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }

      if let error {
        Section {
          Text(error).foregroundStyle(.red)
        }
      }

      Section {
        Button {
          Task { await finish() }
        } label: {
          HStack {
            Spacer()
            if busy { ProgressView().padding(.trailing, 8) }
            Text("Continue")
            Spacer()
          }
        }
        .disabled(busy || (role == .tenant && leaseCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
      }
    }
    .navigationTitle("Set up")
  }

  private func finish() async {
    guard let user = Auth.auth().currentUser else { return }
    busy = true
    defer { busy = false }
    error = nil

    do {
      let email = user.email ?? ""
      if role == .tenant {
        _ = try await FirebaseService.shared.redeemLeaseCode(code: leaseCode.trimmingCharacters(in: .whitespacesAndNewlines), uid: user.uid, email: email)
      } else {
        try await FirebaseService.shared.upsertUser(uid: user.uid, user: AppUser(role: .manager, email: email, displayName: nil, leaseId: nil, createdAt: nil, updatedAt: nil))
      }
      await session.loadProfile()
    } catch {
      self.error = error.localizedDescription
    }
  }
}
