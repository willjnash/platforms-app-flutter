import Foundation

// MARK: - Wire types (private, JSON decoding only)

private enum Wire {
  struct LocationLineUp: Decodable {
    let scheduleMetadata: ScheduleMetadata?
    let temporalData: TemporalData?
    let locationMetadata: LocationMetadata?
    let origin: [LocationPair]?
    let destination: [LocationPair]?
  }

  struct ScheduleMetadata: Decodable {
    let identity: String?
    let departureDate: String?
    let trainReportingIdentity: String?
    let `operator`: OperatorInfo?
  }

  struct OperatorInfo: Decodable {
    let name: String?
  }

  struct TemporalData: Decodable {
    let arrival: IndividualTemporalData?
    let departure: IndividualTemporalData?
    let displayAs: String?
    let scheduledCallType: String?
  }

  struct IndividualTemporalData: Decodable {
    let scheduleAdvertised: String?
    let realtimeForecast: String?
    let realtimeActual: String?
  }

  struct LocationMetadata: Decodable {
    let platform: PlannedActual?
  }

  struct PlannedActual: Decodable {
    let planned: String?
    let actual: String?
  }

  struct LocationPair: Decodable {
    let location: GeoLocation?
    let temporalData: IndividualTemporalData?
  }

  struct GeoLocation: Decodable {
    let description: String?
  }

  struct ServiceDetailRoot: Decodable {
    let service: ServiceDetail?
  }

  struct ServiceDetail: Decodable {
    let scheduleMetadata: ScheduleMetadata?
    let locations: [ServiceLocationWire]?
    let origin: [LocationPair]?
    let destination: [LocationPair]?
  }

  struct ServiceLocationWire: Decodable {
    let temporalData: TemporalData?
    let locationMetadata: LocationMetadata?
    let location: GeoLocation?
  }
}

// MARK: - Search (departures / arrivals)

struct DeparturesResponse {
  var services: [ServiceSummary]?

  init(services: [ServiceSummary]?) {
    self.services = services
  }
}

extension DeparturesResponse: Decodable {
  init(from decoder: Decoder) throws {
    let root = try decoder.container(keyedBy: CodingKeys.self)
    let raw = try root.decodeIfPresent([Wire.LocationLineUp].self, forKey: .services)
    services = raw?.map { ServiceSummary(lineup: $0) }
  }
  enum CodingKeys: String, CodingKey { case services }
}

struct ServiceSummary: Identifiable, Hashable {
  var id: String { "\(serviceUid ?? "")-\(runDate ?? "")" }

  let locationDetail: LocationDetail?
  let serviceUid: String?
  let runDate: String?
  let trainIdentity: String?
  let atocName: String?

  fileprivate init(lineup: Wire.LocationLineUp) {
    let sm = lineup.scheduleMetadata
    serviceUid = sm?.identity
    runDate = sm?.departureDate
    trainIdentity = sm?.trainReportingIdentity ?? sm?.identity
    atocName = sm?.operator?.name
    locationDetail = LocationDetail(lineup: lineup)
  }
}

struct LocationDetail: Hashable {
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

  fileprivate init(lineup: Wire.LocationLineUp) {
    let td = lineup.temporalData
    let dep = td?.departure
    let arr = td?.arrival

    gbttBookedDeparture = TimeFormatting.hhmmFromISO(dep?.scheduleAdvertised)
    gbttBookedArrival = TimeFormatting.hhmmFromISO(arr?.scheduleAdvertised)

    let rtDep = dep?.realtimeActual ?? dep?.realtimeForecast
    let rtArr = arr?.realtimeActual ?? arr?.realtimeForecast
    realtimeDeparture = TimeFormatting.hhmmFromISO(rtDep)
    realtimeArrival = TimeFormatting.hhmmFromISO(rtArr)
    realtimeDepartureActual = dep?.realtimeActual != nil
    realtimeArrivalActual = arr?.realtimeActual != nil
    realtimeActivated = dep?.realtimeForecast != nil || dep?.realtimeActual != nil

    let platformPlanned = lineup.locationMetadata?.platform?.planned
    let platformActual = lineup.locationMetadata?.platform?.actual
    platform = platformActual ?? platformPlanned
    platformConfirmed = platformActual != nil
    platformChanged = platformActual != nil && platformActual != platformPlanned

    displayAs = td?.displayAs

    let originDesc = lineup.origin?.first?.location?.description
    origin = originDesc.map { [CallPointRef(description: $0, publicTime: nil)] }

    // destination.first.publicTime carries this station's arrival HHmm, used by the arrivals row.
    let destDesc = lineup.destination?.first?.location?.description
    let arrHHmm = TimeFormatting.hhmmFromISO(arr?.scheduleAdvertised)
    if destDesc != nil || arrHHmm != nil {
      destination = [CallPointRef(description: destDesc, publicTime: arrHHmm)]
    } else {
      destination = nil
    }
  }
}

struct CallPointRef: Hashable {
  let description: String?
  let publicTime: String?
}

// MARK: - Service detail

struct ServiceDetailResponse {
  let serviceUid: String?
  let runDate: String?
  let trainIdentity: String?
  let atocName: String?
  let origin: [CallPointRef]?
  let destination: [CallPointRef]?
  let locations: [ServiceLocation]?
}

extension ServiceDetailResponse: Decodable {
  init(from decoder: Decoder) throws {
    let root = try decoder.container(keyedBy: RootKeys.self)
    let wire = try root.decodeIfPresent(Wire.ServiceDetail.self, forKey: .service)

    let sm = wire?.scheduleMetadata
    serviceUid = sm?.identity
    runDate = sm?.departureDate
    trainIdentity = sm?.trainReportingIdentity ?? sm?.identity
    atocName = sm?.operator?.name

    origin = wire?.origin?.compactMap { pair -> CallPointRef? in
      let desc = pair.location?.description
      let time = TimeFormatting.hhmmFromISO(pair.temporalData?.scheduleAdvertised)
      guard desc != nil || time != nil else { return nil }
      return CallPointRef(description: desc, publicTime: time)
    }

    destination = wire?.destination?.compactMap { pair -> CallPointRef? in
      guard let desc = pair.location?.description else { return nil }
      return CallPointRef(description: desc, publicTime: nil)
    }

    locations = wire?.locations?.map { ServiceLocation(wire: $0) }
  }

  enum RootKeys: String, CodingKey { case service }
}

struct ServiceLocation {
  let description: String?
  let origin: [CallPointRef]?       // always nil in v2 API
  let destination: [CallPointRef]?  // always nil in v2 API
  let isPublicCall: Bool?
  let gbttBookedArrival: String?
  let gbttBookedDeparture: String?
  let realtimeArrival: String?
  let realtimeDeparture: String?
  let platform: String?
  let platformConfirmed: Bool?
  let displayAs: String?

  fileprivate init(wire: Wire.ServiceLocationWire) {
    description = wire.location?.description
    origin = nil
    destination = nil

    let td = wire.temporalData
    let callType = td?.scheduledCallType
    isPublicCall = callType != nil && callType != "OPERATIONAL_ONLY"

    gbttBookedArrival = TimeFormatting.hhmmFromISO(td?.arrival?.scheduleAdvertised)
    gbttBookedDeparture = TimeFormatting.hhmmFromISO(td?.departure?.scheduleAdvertised)
    realtimeArrival = TimeFormatting.hhmmFromISO(td?.arrival?.realtimeActual ?? td?.arrival?.realtimeForecast)
    realtimeDeparture = TimeFormatting.hhmmFromISO(td?.departure?.realtimeActual ?? td?.departure?.realtimeForecast)

    let platformActual = wire.locationMetadata?.platform?.actual
    let platformPlanned = wire.locationMetadata?.platform?.planned
    platform = platformActual ?? platformPlanned
    platformConfirmed = platformActual != nil

    displayAs = td?.displayAs
  }
}
