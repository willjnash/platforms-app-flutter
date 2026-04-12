import SwiftUI

struct StationPickerSheet: View {
  @Environment(\.dismiss) private var dismiss

  var selectedCRS: String
  var onPick: (Station) -> Void
  var title: String = L10n.stationTitle

  @State private var searchText = ""

  private var filteredStations: [Station] {
    if searchText.isEmpty {
      return StationCatalog.stations
    }
    let query = searchText.lowercased()
    return StationCatalog.stations.filter {
      $0.displayName.lowercased().contains(query) || $0.crs.lowercased().contains(query)
    }
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(filteredStations) { station in
          Button {
            onPick(station)
            dismiss()
          } label: {
            HStack {
              Text(station.displayName)
              Spacer()
              if station.crs == selectedCRS {
                Image(systemName: "checkmark")
                  .fontWeight(.semibold)
                  .foregroundStyle(Color.accentColor)
              }
              Text(station.crs)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .monospaced()
            }
            .contentShape(Rectangle())
          }
          .tint(.primary)
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(L10n.cancel, role: .cancel) { dismiss() }
        }
      }
    }
    .presentationDragIndicator(.visible)
    .presentationDetents([.medium, .large])
  }
}
