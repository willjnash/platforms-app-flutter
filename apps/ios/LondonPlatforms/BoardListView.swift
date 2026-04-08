import SwiftUI

/// Adaptive board list: push navigation on compact, selection-driven on regular width.
struct BoardListView: View {
  @Bindable var model: BoardViewModel
  @Binding var selectedService: ServiceSummary?
  @Environment(\.horizontalSizeClass) private var sizeClass

  @State private var showStationPicker = false
  @State private var showTimePicker = false
  @State private var showAbout = false

  private var isCompact: Bool { sizeClass == .compact }

  var body: some View {
    List(selection: isCompact ? nil : $selectedService) {
      Section {
        Picker(L10n.boardSection, selection: $model.showingArrivals) {
          Text(L10n.departures).tag(false)
          Text(L10n.arrivals).tag(true)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(L10n.boardPickerAccessibility)
        .padding(.vertical, 6)
      } footer: {
        VStack(alignment: .leading, spacing: 6) {
          Text(model.scheduleContextDescription)
            .font(.footnote)
            .foregroundStyle(.secondary)
          if let last = model.lastRefreshLabel {
            Text(L10n.lastUpdated(at: last))
              .font(.caption)
              .foregroundStyle(.tertiary)
          }
        }
      }

      if let err = model.errorMessage {
        Section {
          Label {
            Text(err)
              .foregroundStyle(.primary)
          } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
              .symbolRenderingMode(.hierarchical)
              .foregroundStyle(.orange)
          }
          .accessibilityLabel(err)
        }
      }

      servicesSection
    }
    .listStyle(.insetGrouped)
    .navigationTitle(model.navigationTitle)
    .navigationBarTitleDisplayMode(.large)
    .refreshable {
      await model.load(userInitiated: true)
    }
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        if model.isLoading {
          ProgressView()
            .controlSize(.regular)
        } else {
          Button {
            Task { await model.load(userInitiated: true) }
          } label: {
            Image(systemName: "arrow.clockwise")
          }
          .accessibilityLabel(L10n.refresh)
        }

        Menu {
          Button {
            showStationPicker = true
          } label: {
            Label(L10n.menuStation, systemImage: "mappin.and.ellipse")
          }
          Button {
            showTimePicker = true
          } label: {
            Label(L10n.menuTimeFilter, systemImage: "clock")
          }
          Divider()
          Button {
            showAbout = true
          } label: {
            Label(L10n.menuAbout, systemImage: "info.circle")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel(L10n.moreMenu)
      }
    }
    .task {
      await model.load()
    }
    .onChange(of: model.showingArrivals) { _, _ in
      selectedService = nil
      model.persistBoardPreferences()
      Task { await model.load() }
    }
    .onChange(of: model.filterTimeHHmm) { _, _ in
      model.persistBoardPreferences()
    }
    .onChange(of: model.services) { _, _ in
      pruneSelectionIfStale()
    }
    .sheet(isPresented: $showStationPicker) {
      StationPickerSheet(
        selectedCRS: model.stationCRS,
        onPick: { station in
          model.applyStation(station)
          selectedService = nil
          Task { await model.load() }
        }
      )
    }
    .sheet(isPresented: $showTimePicker) {
      TimeFilterSheet(timeHHmm: $model.filterTimeHHmm)
        .onDisappear {
          model.persistBoardPreferences()
          Task { await model.load() }
        }
    }
    .sheet(isPresented: $showAbout) {
      AboutSheet()
    }
  }

  private func pruneSelectionIfStale() {
    guard let current = selectedService else { return }
    if !model.filteredServices.contains(where: { $0.id == current.id }) {
      selectedService = nil
    }
  }

  @ViewBuilder
  private var servicesSection: some View {
    let rows = model.filteredServices
    if model.isLoading && rows.isEmpty && model.errorMessage == nil {
      Section {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding(.vertical, 28)
          .listRowBackground(Color.clear)
      }
    } else if !model.isLoading && model.errorMessage == nil && rows.isEmpty {
      Section {
        ContentUnavailableView(
          L10n.noServicesTitle,
          systemImage: "clock",
          description: Text(L10n.noServicesDescription)
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowBackground(Color.clear)
      }
    } else {
      Section {
        ForEach(rows) { item in
          if let uid = item.serviceUid, let date = item.runDate, let ld = item.locationDetail {
            serviceRow(item: item, uid: uid, date: date, ld: ld)
          }
        }
      } header: {
        Text(model.showingArrivals ? L10n.sectionArrivals : L10n.sectionDepartures)
      }
    }
  }

  @ViewBuilder
  private func serviceRow(item: ServiceSummary, uid: String, date: String, ld: LocationDetail) -> some View {
    let rowContent = Group {
      if model.showingArrivals {
        ServiceRows.Arrival(item: item, locationDetail: ld)
      } else {
        ServiceRows.Departure(item: item, locationDetail: ld)
      }
    }

    if isCompact {
      NavigationLink {
        ServiceDetailView(serviceUid: uid, runDate: date)
      } label: {
        rowContent
      }
      .confirmedDepartureStyle(
        isConfirmed: !model.showingArrivals && ld.platformConfirmed == true
      )
    } else {
      rowContent
        .tag(item)
        .confirmedDepartureStyle(
          isConfirmed: !model.showingArrivals && ld.platformConfirmed == true
        )
    }
  }
}
