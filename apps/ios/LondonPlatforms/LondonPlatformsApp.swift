import SwiftUI

@main
struct LondonPlatformsApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .onAppear {
          BackgroundRefresh.register()
          BackgroundRefresh.scheduleNext()
        }
    }
  }
}
