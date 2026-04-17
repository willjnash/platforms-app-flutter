import SwiftUI

struct RootView: View {
  @State private var model = BoardViewModel()
  @State private var selectedTab: AppTab = .board

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab(L10n.tabBoard, systemImage: "list.bullet.rectangle", value: .board) {
        BoardTab(model: model)
      }

      Tab(L10n.tabSettings, systemImage: "gear", value: .settings) {
        NavigationStack {
          SettingsView()
        }
      }
    }
  }
}

enum AppTab: Hashable {
  case board
  case settings
}

// MARK: - Board tab: adaptive layout

/// Compact: NavigationStack with station button in toolbar.
/// Regular: NavigationSplitView with station sidebar.
private struct BoardTab: View {
  @Bindable var model: BoardViewModel
  @State private var selectedService: ServiceSummary?
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    if sizeClass == .compact {
      NavigationStack {
        BoardListView(model: model, selectedService: $selectedService, showsStationButton: true)
      }
      .sheet(item: $selectedService) { service in
        if let uid = service.serviceUid, let rd = service.runDate {
          ServiceDetailView(
            serviceUid: uid,
            runDate: rd,
            boardContext: service.locationDetail.map {
              ServiceDetailBoardContext(locationDetail: $0, showingArrivals: model.showingArrivals)
            }
          )
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
        }
      }
    } else {
      NavigationSplitView {
        StationSidebarView(model: model)
      } detail: {
        NavigationStack {
          BoardListView(model: model, selectedService: $selectedService, showsStationButton: false)
        }
        .sheet(item: $selectedService) { service in
          if let uid = service.serviceUid, let rd = service.runDate {
            ServiceDetailView(
              serviceUid: uid,
              runDate: rd,
              boardContext: service.locationDetail.map {
                ServiceDetailBoardContext(locationDetail: $0, showingArrivals: model.showingArrivals)
              }
            )
              .presentationDragIndicator(.visible)
              .presentationDetents([.medium, .large])
          }
        }
      }
    }
  }
}

// MARK: - iPad station sidebar

private struct StationSidebarView: View {
  @Bindable var model: BoardViewModel

  private var selectedCRS: Binding<String?> {
    Binding(
      get: { model.stationCRS },
      set: { newCRS in
        guard let newCRS else { return }
        let station = StationCatalog.station(crs: newCRS)
        model.applyStation(station)
        Task { await model.load() }
      }
    )
  }

  var body: some View {
    List(selection: selectedCRS) {
      ForEach(StationCatalog.stations) { station in
        Label {
          VStack(alignment: .leading) {
            Text(station.displayName)
            Text(station.crs)
              .font(.caption)
              .foregroundStyle(.tertiary)
              .monospaced()
          }
        } icon: {
          Image(systemName: "tram.fill")
            .foregroundStyle(.secondary)
        }
        .tag(station.crs)
      }
    }
    .listStyle(.sidebar)
    .navigationTitle(L10n.stationsTitle)
  }
}
