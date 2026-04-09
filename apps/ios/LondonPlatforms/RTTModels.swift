import Foundation

// MARK: - Search (departures / arrivals)

struct DeparturesResponse: Decodable {
  var services: [ServiceSummary]?

  enum CodingKeys: String, CodingKey {
    case services
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    services = try c.decodeIfPresent([ServiceSummary].self, forKey: .services)
  }
}

struct ServiceSummary: Decodable, Identifiable, Hashable {
  var id: String { "\(serviceUid ?? "")-\(runDate ?? "")" }

  let locationDetail: LocationDetail?
  let serviceUid: String?
  let runDate: String?
  let trainIdentity: String?
  let atocName: String?
}

struct LocationDetail: Decodable, Hashable {
  let realtimeActivated: Bool?
  let gbttBookedDeparture: String?
  let gbttBookedArrival: String?
  let origin: [CallPointRef]?
  let destination: [CallPointRef]?
  let realtimeDeparture: String?
  let realtimeDepartureActual: Bool?
  let realtimeArrival: String?
  let realtimeArrivalActual: Bool?
  let platform: String?
  let platformConfirmed: Bool?
  let platformChanged: Bool?
  let displayAs: String?
}

struct CallPointRef: Decodable, Hashable {
  let description: String?
  let publicTime: String?
}

// MARK: - Service detail

struct ServiceDetailResponse: Decodable {
  let serviceUid: String?
  let runDate: String?
  let trainIdentity: String?
  let atocName: String?
  let origin: [CallPointRef]?
  let destination: [CallPointRef]?
  let locations: [ServiceLocation]?
}

struct ServiceLocation: Decodable {
  let description: String?
  let origin: [CallPointRef]?
  let destination: [CallPointRef]?
  let isPublicCall: Bool?
  let gbttBookedArrival: String?
  let gbttBookedDeparture: String?
  let realtimeArrival: String?
  let realtimeDeparture: String?
  let platform: String?
  let platformConfirmed: Bool?
  let displayAs: String?
}
