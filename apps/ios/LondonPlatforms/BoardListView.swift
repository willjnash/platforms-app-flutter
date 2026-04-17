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
    boardListWithSheets
  }

  private var boardListWithSheets: some View {
    boardListWithSceneObservers
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

  private var boardListWithSceneObservers: some View {
    boardListWithModelObservers
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
  }

  private var boardListWithModelObservers: some View {
    boardListWithToolbar
      .task {
        await model.load()
        model.startAutoRefresh()
      }
      .onChange(of: model.showingArrivals) { _, _ in
        selectedService = nil
        model.resetBoard()
        model.persistBoardPreferences()
        Task { await model.load() }
      }
      .onChange(of: model.filterTimeHHmm) { _, newValue in
        model.resetBoard()
        model.persistBoardPreferences()
        Task { await model.load() }
        if newValue == nil {
          model.startAutoRefresh()
        } else {
          model.stopAutoRefresh()
        }
      }
      .onChange(of: model.filterToCRS) { _, _ in
        model.resetBoard()
        model.persistBoardPreferences()
        Task { await model.load() }
      }
  }

  private var boardListWithToolbar: some View {
    boardListStyled
      .toolbar {
        if showsStationButton {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              showStationPicker = true
            } label: {
              Image(systemName: "mappin.and.ellipse")
                .font(.body.weight(.medium))
                .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("\(L10n.changeStation). \(model.stationDesc)")
          }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
          filterMenu
          refreshIndicator
        }
      }
  }

  private var boardListStyled: some View {
    boardList
      .listStyle(.insetGrouped)
      .contentMargins(.top, 0, for: .scrollContent)
      .contentMargins(.bottom, 88, for: .scrollContent)
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .refreshable {
        await model.load(userInitiated: true)
      }
  }

  private var boardList: some View {
    List {
      statusHeaderRow

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
  }

  // MARK: - Status section

  private var statusHeaderRow: some View {
    VStack(spacing: 6) {
      Text(model.navigationTitle)
        .font(.largeTitle.weight(.bold))
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(2)
        .minimumScaleFactor(0.85)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 4)

      HStack(spacing: 8) {
        BoardModePill(
          title: L10n.departures,
          systemImage: "arrow.up.forward",
          isSelected: !model.showingArrivals
        ) {
          model.showingArrivals = false
        }
        BoardModePill(
          title: L10n.arrivals,
          systemImage: "arrow.down.forward",
          isSelected: model.showingArrivals
        ) {
          model.showingArrivals = true
        }
        Spacer(minLength: 0)
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel(L10n.boardPickerAccessibility)

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
    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
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

private struct BoardModePill: View {
  let title: String
  let systemImage: String
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      Label(title, systemImage: systemImage)
        .font(.headline.weight(.semibold))
        .labelStyle(.titleAndIcon)
        .foregroundStyle(isSelected ? .white : .secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          isSelected ? Color(.tertiaryLabel) : Color(.quaternarySystemFill),
          in: Capsule()
        )
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
  }
}
