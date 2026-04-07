import SwiftUI

/// Two-column layout on iPad (and wide iPhone landscape where applicable); stacks on compact width.
struct RootView: View {
  @StateObject private var model = BoardViewModel()
  @State private var selectedService: ServiceSummary?
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    Group {
      if horizontalSizeClass == .compact {
        NavigationStack {
          BoardListCompactView(model: model)
        }
      } else {
        NavigationSplitView {
          NavigationStack {
            BoardListView(model: model, selectedService: $selectedService)
          }
        } detail: {
          NavigationStack {
            if let sel = selectedService,
               let uid = sel.serviceUid,
               let rd = sel.runDate {
              ServiceDetailView(serviceUid: uid, runDate: rd)
            } else {
              ContentUnavailableView(
                L10n.selectTrainTitle,
                systemImage: "tram.fill",
                description: Text(L10n.selectTrainDescription)
              )
            }
          }
        }
      }
    }
    .onOpenURL { url in
      guard url.scheme == "londonplatforms" else { return }
      guard url.host == "refresh" else { return }
      Task {
        await model.load(userInitiated: true)
      }
    }
  }
}
