import SwiftUI
import FirebaseAuth

struct AuthView: View {
  @EnvironmentObject var session: SessionStore

  @State private var mode: Mode = .login
  @State private var email: String = ""
  @State private var password: String = ""
  @State private var busy: Bool = false
  @State private var error: String?

  enum Mode: String {
    case login
    case signup

    var title: String { self == .login ? "Log in" : "Sign up" }
    var toggleLabel: String {
      self == .login ? "Need an account? Sign up" : "Have an account? Log in"
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Email", text: $email)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

          SecureField("Password", text: $password)
        }

        if let error {
          Section {
            Text(error)
              .foregroundStyle(.red)
          }
        }

        Section {
          Button {
            Task { await submit() }
          } label: {
            HStack {
              Spacer()
              if busy { ProgressView().padding(.trailing, 8) }
              Text(mode.title)
              Spacer()
            }
          }
          .disabled(busy || email.isEmpty || password.isEmpty)

          Button(mode.toggleLabel) {
            mode = (mode == .login) ? .signup : .login
            error = nil
          }
        }
      }
      .navigationTitle("Karberg Properties")
    }
  }

  private func submit() async {
    busy = true
    defer { busy = false }
    error = nil

    do {
      switch mode {
      case .login:
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
      case .signup:
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
      }
      await session.loadProfile()
    } catch {
      self.error = error.localizedDescription
    }
  }
}
