import Foundation
import ActivityKit

/// Shared models for Live Activity attributes/state.
struct TrackedServiceAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var stationName: String
    var destinationName: String
    var bookedDepartureHHmm: String
    var expectedDepartureHHmm: String?
    var platform: String?
    var platformConfirmed: Bool
    var platformChanged: Bool
    var departed: Bool
    var lastCheckedAt: Date
    var nextCheckAt: Date
  }

  var serviceUid: String
  var runDate: String
}

