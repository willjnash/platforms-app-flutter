import SwiftUI

struct BoardListView: View {
  @Bindable var model: BoardViewModel
  @Binding var selectedService: ServiceSummary?
  var showsStationButton: Bool

  @State private var showStationPicker = false
  @State private var showTimePicker = false
  @State private var showTowardsPicker = false
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
        .accessibilityLabel(L10n.boardPickerAccessibility)
      }

      ToolbarItemGroup(placement: .topBarTrailing) {
        filterMenu
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
    .onChange(of: model.filterToCRS) { _, _ in
      model.persistBoardPreferences()
      Task { await model.load() }
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
    .sheet(isPresented: $showTowardsPicker) {
      StationPickerSheet(
        selectedCRS: model.filterToCRS ?? "",
        onPick: { station in model.filterToCRS = station.crs },
        title: L10n.towardsFilterTitle
      )
    }
  }

  // MARK: - Status section

  private var statusSection: some View {
    Section {
      VStack(spacing: 6) {
        // System status banner
        if let banner = model.systemStatus?.bannerMessage {
          HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
              .foregroundStyle(.orange)
              .font(.subheadline)
            Text(banner)
              .font(.subheadline)
              .foregroundStyle(.orange)
            Spacer()
          }
          .padding(.vertical, 2)
          .accessibilityLabel(banner)
        }

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

        // Active filter chips — shown inline, no extra section gap
        if hasActiveFilters {
          HStack(spacing: 8) {
            if let crs = model.filterToCRS {
              FilterChip(label: L10n.activeFilterTowards(crs.uppercased())) {
                model.filterToCRS = nil
              }
            }
            if let hhmm = model.filterTimeHHmm {
              FilterChip(label: L10n.activeFilterTime(TimeFormatting.displayHHmm(hhmm))) {
                model.filterTimeHHmm = nil
              }
            }
            Spacer()
          }
        }
      }
      .listRowBackground(Color.clear)
    }
  }

  // MARK: - Filter menu

  private var hasActiveFilters: Bool {
    model.filterToCRS != nil || model.filterTimeHHmm != nil
  }

  private var filterMenu: some View {
    Menu {
      Button(L10n.filterByDestination, systemImage: "arrowshape.forward") {
        showTowardsPicker = true
      }
      Button(L10n.filterByTime, systemImage: "clock") {
        showTimePicker = true
      }
      if hasActiveFilters {
        Divider()
        Button(L10n.clearFilters, systemImage: "xmark.circle", role: .destructive) {
          model.filterToCRS = nil
          model.filterTimeHHmm = nil
        }
      }
    } label: {
      Image(systemName: hasActiveFilters
            ? "line.3.horizontal.decrease.circle.fill"
            : "line.3.horizontal.decrease.circle")
    }
    .accessibilityLabel(L10n.filterMenuLabel)
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

// MARK: - Filter chip

private struct FilterChip: View {
  let label: String
  let onClear: () -> Void

  var body: some View {
    Button(action: onClear) {
      HStack(spacing: 4) {
        Text(label)
          .font(.caption.weight(.medium))
        Image(systemName: "xmark.circle.fill")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .foregroundStyle(.primary)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(Color.secondary.opacity(0.12), in: Capsule())
    }
    .buttonStyle(.plain)
  }
}
