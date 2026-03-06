import SwiftUI
import FirebaseCore

@main
struct KarbergPropertiesApp: App {
  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}
