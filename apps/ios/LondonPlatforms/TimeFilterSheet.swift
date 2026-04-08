import SwiftUI

struct TimeFilterSheet: View {
  @Binding var timeHHmm: String?
  @Environment(\.dismiss) private var dismiss

  @State private var picked: Date

  init(timeHHmm: Binding<String?>) {
    self._timeHHmm = timeHHmm
    let cal = Calendar.current
    let now = Date()
    if let raw = timeHHmm.wrappedValue, raw.count >= 4 {
      var dc = cal.dateComponents(in: TimeZone.current, from: now)
      dc.hour = Int(String(raw.prefix(2)))
      dc.minute = Int(String(raw.dropFirst(2).prefix(2)))
      _picked = State(initialValue: cal.date(from: dc) ?? now)
    } else {
      _picked = State(initialValue: now)
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          DatePicker(
            L10n.timePickerLabel,
            selection: $picked,
            displayedComponents: [.hourAndMinute]
          )
        } footer: {
          Text(L10n.timeFilterFooter)
        }

        Section {
          Button(L10n.clearFilter, role: .destructive) {
            timeHHmm = nil
            dismiss()
          }
        }
      }
      .navigationTitle(L10n.timeFilterTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(L10n.cancel, role: .cancel) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(L10n.apply) {
            let cal = Calendar.current
            let c = cal.dateComponents([.hour, .minute], from: picked)
            let h = c.hour ?? 0
            let m = c.minute ?? 0
            timeHHmm = String(format: "%02d%02d", h, m)
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
    .presentationDragIndicator(.visible)
    .presentationDetents([.medium, .large])
  }
}
