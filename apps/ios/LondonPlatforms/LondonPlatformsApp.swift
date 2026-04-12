import SwiftUI

@main
struct LondonPlatformsApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .task {
          StationCatalog.refreshInBackground()
        }
    }
  }
}
