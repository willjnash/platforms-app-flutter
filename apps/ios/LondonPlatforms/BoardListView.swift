import SwiftUI

struct BoardListView: View {
  @Bindable var model: BoardViewModel
  @Binding var selectedService: ServiceSummary?
  var showsStationButton: Bool

  @State private var showStationPicker = false
  @State private var showTimePicker = false
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    List {
      statusSection

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
      if showsStationButton {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            showStationPicker = true
          } label: {
            Label(model.stationDesc, systemImage: "mappin.and.ellipse")
              .labelStyle(.titleAndIcon)
          }
          .accessibilityLabel(L10n.changeStation)
        }
      }

      ToolbarItem(placement: .principal) {
        Picker(L10n.boardSection, selection: $model.showingArrivals) {
          Text(L10n.departures).tag(false)
          Text(L10n.arrivals).tag(true)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 220)
        .accessibilityLabel(L10n.boardPickerAccessibility)
      }

      ToolbarItemGroup(placement: .topBarTrailing) {
        timeFilterButton
        refreshIndicator
      }
    }
    .task {
      await model.load()
      model.startAutoRefresh()
    }
    .onChange(of: model.showingArrivals) { _, _ in
      selectedService = nil
      model.persistBoardPreferences()
      Task { await model.load() }
    }
    .onChange(of: model.filterTimeHHmm) { _, newValue in
      model.persistBoardPreferences()
      Task { await model.load() }
      if newValue == nil {
        model.startAutoRefresh()
      } else {
        model.stopAutoRefresh()
      }
    }
    .onChange(of: scenePhase) { _, newPhase in
      switch newPhase {
      case .active:
        Task { await model.load() }
        model.startAutoRefresh()
      case .background, .inactive:
        model.stopAutoRefresh()
      @unknown default:
        break
      }
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
    }
  }

  // MARK: - Status section (live indicator + last updated)

  private var statusSection: some View {
    Section {
      HStack(spacing: 8) {
        if model.isLive {
          HStack(spacing: 4) {
            Circle()
              .fill(.green)
              .frame(width: 8, height: 8)
            Text(L10n.liveLabel)
              .font(.subheadline.weight(.medium))
              .foregroundStyle(.green)
          }
          .accessibilityLabel(L10n.liveA11y)
        }

        Text(model.scheduleContextDescription)
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Spacer()

        if let last = model.lastRefreshLabel {
          Text(last)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .monospacedDigit()
        }
      }
      .listRowBackground(Color.clear)
    }
  }

  // MARK: - Time filter button

  @ViewBuilder
  private var timeFilterButton: some View {
    if let hhmm = model.filterTimeHHmm {
      Button {
        model.filterTimeHHmm = nil
      } label: {
        HStack(spacing: 2) {
          Text(TimeFormatting.displayHHmm(hhmm))
            .monospacedDigit()
          Image(systemName: "xmark.circle.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .accessibilityLabel(L10n.clearFilter)
    } else {
      Button {
        showTimePicker = true
      } label: {
        Image(systemName: "clock")
      }
      .accessibilityLabel(L10n.menuTimeFilter)
    }
  }

  // MARK: - Refresh / live indicator

  @ViewBuilder
  private var refreshIndicator: some View {
    if model.isLoading {
      ProgressView()
        .controlSize(.regular)
    } else {
      Button {
        Task { await model.load(userInitiated: true) }
        model.startAutoRefresh()
      } label: {
        ZStack {
          if model.isLive {
            Circle()
              .trim(from: 0, to: model.autoRefreshProgress)
              .stroke(Color.green.opacity(0.5), lineWidth: 2)
              .frame(width: 22, height: 22)
              .rotationEffect(.degrees(-90))
              .animation(.linear(duration: 1), value: model.autoRefreshProgress)
          }
          Image(systemName: "arrow.clockwise")
            .font(.body)
        }
      }
      .accessibilityLabel(L10n.refresh)
    }
  }

  // MARK: - Services

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
          if let ld = item.locationDetail {
            Button {
              selectedService = item
            } label: {
              Group {
                if model.showingArrivals {
                  ServiceRows.Arrival(item: item, locationDetail: ld)
                } else {
                  ServiceRows.Departure(item: item, locationDetail: ld)
                }
              }
            }
            .tint(.primary)
            .confirmedDepartureStyle(
              isConfirmed: !model.showingArrivals && ld.platformConfirmed == true
            )
          }
        }
      } header: {
        Text(model.showingArrivals ? L10n.sectionArrivals : L10n.sectionDepartures)
      }
    }
  }
}
