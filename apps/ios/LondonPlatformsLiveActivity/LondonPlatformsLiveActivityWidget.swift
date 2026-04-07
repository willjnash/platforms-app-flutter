import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct LondonPlatformsLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TrackedServiceAttributes.self) { context in
      // Lock Screen — keep content within the system-provided Live Activity width:
      // avoid wide single-line HStacks (relative dates + button overflow easily).
      VStack(alignment: .leading, spacing: 6) {
        Text(context.state.stationName)
          .font(.headline)
          .lineLimit(1)
          .minimumScaleFactor(0.85)

        Text("\(TimeFormatting.displayHHmm(context.state.bookedDepartureHHmm)) → \(context.state.destinationName)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .minimumScaleFactor(0.85)
          .fixedSize(horizontal: false, vertical: true)

        VStack(alignment: .leading, spacing: 4) {
          platformView(context.state)
          secondaryPlatformRow(context.state)
        }

        HStack(alignment: .top, spacing: 10) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Checked \(context.state.lastCheckedAt, style: .time)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .minimumScaleFactor(0.8)

            Text("Next \(context.state.nextCheckAt, style: .relative)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .minimumScaleFactor(0.8)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          Button(intent: RefreshNowIntent()) {
            Image(systemName: "arrow.clockwise")
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Refresh")
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 8)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          platformView(context.state)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.state.destinationName)
            .lineLimit(1)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(TimeFormatting.displayHHmm(context.state.bookedDepartureHHmm))
            .monospacedDigit()
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 4) {
            if let expected = context.state.expectedDepartureHHmm,
               expected != context.state.bookedDepartureHHmm {
              Text("Expected \(TimeFormatting.displayHHmm(expected))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            } else {
              Text("On time")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text("Next check \(context.state.nextCheckAt, style: .relative)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .minimumScaleFactor(0.85)
              .fixedSize(horizontal: false, vertical: true)

            HStack {
              Spacer(minLength: 0)
              Button(intent: RefreshNowIntent()) {
                Image(systemName: "arrow.clockwise")
              }
              .buttonStyle(.borderless)
              .accessibilityLabel("Refresh")
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      } compactLeading: {
        Text(context.state.platformConfirmed ? (context.state.platform ?? "—") : "—")
      } compactTrailing: {
        Text(TimeFormatting.displayHHmm(context.state.bookedDepartureHHmm))
          .monospacedDigit()
      } minimal: {
        Image(systemName: "train.side.front.car")
      }
    }
  }

  @ViewBuilder
  private func platformView(_ state: TrackedServiceAttributes.ContentState) -> some View {
    if let p = state.platform, !p.isEmpty {
      Text("Plat \(p)\(state.platformConfirmed ? "" : "?")")
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    } else {
      Text("Platform —")
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }

  @ViewBuilder
  private func secondaryPlatformRow(_ state: TrackedServiceAttributes.ContentState) -> some View {
    let showExpected =
      state.expectedDepartureHHmm.map { $0 != state.bookedDepartureHHmm } ?? false
    if showExpected || state.platformChanged {
      HStack(spacing: 6) {
        if let expected = state.expectedDepartureHHmm, showExpected {
          Text("Exp \(TimeFormatting.displayHHmm(expected))")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        if state.platformChanged {
          Text("Changed")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.thinMaterial, in: Capsule())
            .lineLimit(1)
        }
      }
    }
  }
}

@main
struct LondonPlatformsWidgetBundle: WidgetBundle {
  var body: some Widget {
    LondonPlatformsLiveActivityWidget()
  }
}

