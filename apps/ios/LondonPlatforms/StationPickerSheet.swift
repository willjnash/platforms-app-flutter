import SwiftUI

struct StationPickerSheet: View {
  @Environment(\.dismiss) private var dismiss

  var selectedCRS: String
  var onPick: (Station) -> Void

  var body: some View {
    NavigationStack {
      List {
        ForEach(StationCatalog.stations) { station in
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
      .navigationTitle(L10n.stationTitle)
      .navigationBarTitleDisplayMode(.inline)
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
