import ActivityKit
import Foundation

@MainActor
final class TrackedServiceManager: ObservableObject {
  static let shared = TrackedServiceManager()

  @Published private(set) var trackedKey: String?

  private init() {
    trackedKey = UserDefaults.standard.string(forKey: Self.trackedKeyDefaults)
  }

  private static let trackedKeyDefaults = "trackedServiceKey"
  private static let trackedStationNameDefaults = "trackedStationName"
  private static let trackedStationCRSDefaults = "trackedStationCRS"
  private static let trackedDestinationDefaults = "trackedDestinationName"
  private static let trackedBookedDefaults = "trackedBookedHHmm"

  func isTracking(serviceUid: String?, runDate: String?) -> Bool {
    guard let serviceUid, let runDate else { return false }
    return trackedKey == Self.makeKey(serviceUid: serviceUid, runDate: runDate)
  }

  func startTracking(
    serviceUid: String,
    runDate: String,
    stationName: String,
    stationCRS: String,
    destinationName: String,
    bookedDepartureHHmm: String
  ) async {
    let key = Self.makeKey(serviceUid: serviceUid, runDate: runDate)
    trackedKey = key
    UserDefaults.standard.set(key, forKey: Self.trackedKeyDefaults)
    UserDefaults.standard.set(stationName, forKey: Self.trackedStationNameDefaults)
    UserDefaults.standard.set(stationCRS, forKey: Self.trackedStationCRSDefaults)
    UserDefaults.standard.set(destinationName, forKey: Self.trackedDestinationDefaults)
    UserDefaults.standard.set(bookedDepartureHHmm, forKey: Self.trackedBookedDefaults)

    let attributes = TrackedServiceAttributes(serviceUid: serviceUid, runDate: runDate)
    let initial = TrackedServiceAttributes.ContentState(
      stationName: stationName,
      destinationName: destinationName,
      bookedDepartureHHmm: bookedDepartureHHmm,
      expectedDepartureHHmm: nil,
      platform: nil,
      platformConfirmed: false,
      platformChanged: false,
      departed: false,
      lastCheckedAt: Date(),
      nextCheckAt: Date().addingTimeInterval(
        TimeUtils.nextCheckIntervalSeconds(bookedHHmm: bookedDepartureHHmm)
      )
    )
    do {
      _ = try Activity.request(
        attributes: attributes,
        content: .init(state: initial, staleDate: nil),
        pushType: nil
      )
    } catch {
      // If the system refuses the request, clear tracking so UI doesn’t lie.
      await stopTracking()
    }

    BackgroundRefresh.scheduleNext()
  }

  func stopTracking() async {
    trackedKey = nil
    UserDefaults.standard.removeObject(forKey: Self.trackedKeyDefaults)
    UserDefaults.standard.removeObject(forKey: Self.trackedStationCRSDefaults)
    for activity in Activity<TrackedServiceAttributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }

  var trackedStationCRS: String? {
    UserDefaults.standard.string(forKey: Self.trackedStationCRSDefaults)
  }

  func updateFromBoard(
    stationName: String,
    services: [ServiceSummary]
  ) async {
    guard let key = trackedKey else { return }
    guard let (uid, runDate) = Self.parseKey(key) else { return }

    guard
      let item = services.first(where: { $0.serviceUid == uid && $0.runDate == runDate }),
      let ld = item.locationDetail,
      let dest = ld.destination?.first?.description,
      let booked = ld.gbttBookedDeparture
    else { return }

    let state = TrackedServiceAttributes.ContentState(
      stationName: stationName,
      destinationName: dest,
      bookedDepartureHHmm: booked,
      expectedDepartureHHmm: ld.realtimeDeparture,
      platform: ld.platform,
      platformConfirmed: ld.platformConfirmed == true,
      platformChanged: ld.platformChanged == true,
      departed: ld.realtimeDepartureActual == true,
      lastCheckedAt: Date(),
      nextCheckAt: Date().addingTimeInterval(
        TimeUtils.nextCheckIntervalSeconds(bookedHHmm: booked)
      )
    )

    for activity in Activity<TrackedServiceAttributes>.activities {
      guard activity.attributes.serviceUid == uid, activity.attributes.runDate == runDate else { continue }
      await activity.update(.init(state: state, staleDate: nil))
      if state.departed {
        await activity.end(
          .init(state: state, staleDate: nil),
          dismissalPolicy: .after(Date().addingTimeInterval(10 * 60))
        )
        await stopTracking()
      }
    }
  }

  private static func makeKey(serviceUid: String, runDate: String) -> String {
    "\(serviceUid)|\(runDate)"
  }

  private static func parseKey(_ key: String) -> (String, String)? {
    let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
    guard parts.count == 2 else { return nil }
    return (parts[0], parts[1])
  }
}

