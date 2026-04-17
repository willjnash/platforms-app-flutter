import Foundation

// MARK: - Wire types (private, JSON decoding only)

private enum Wire {

  // MARK: Shared building blocks

  struct ReasonBlock: Decodable {
    let type: String?       // DELAY | CANCEL
    let shortText: String?
  }

  struct AssociationData: Decodable {
    let associationType: String?  // JOIN_FROM | JOIN_INTO | DIVIDE_INTO | DIVIDE_FROM | FORM_INTO | FORM_FROM
    let isPublic: Bool?
  }

  struct AssociatedService: Decodable {
    let associationData: AssociationData?
    let scheduleMetadata: ScheduleMetadata?
  }

  struct ScheduleMetadata: Decodable {
    let identity: String?
    let departureDate: String?
    let trainReportingIdentity: String?
    let `operator`: OperatorInfo?
    let modeType: String?
    let inPassengerService: Bool?
  }

  struct OperatorInfo: Decodable {
    let name: String?
  }

  struct TemporalData: Decodable {
    let arrival: IndividualTemporalData?
    let departure: IndividualTemporalData?
    let pass: IndividualTemporalData?
    let displayAs: String?
    let scheduledCallType: String?
  }

  struct IndividualTemporalData: Decodable {
    let scheduleAdvertised: String?
    let realtimeForecast: String?
    let realtimeActual: String?
    let realtimeAdvertisedLateness: Int?
    let status: String?  // APPROACHING | ARRIVING | AT_PLATFORM | DEPART_PREPARING | DEPART_READY | DEPARTING
  }

  struct LocationMetadata: Decodable {
    let platform: PlannedActual?
    let numberOfVehicles: Int?
    let isRequestStop: Bool?
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

  // MARK: Board (location lineup)

  struct LocationLineUp: Decodable {
    let scheduleMetadata: ScheduleMetadata?
    let temporalData: TemporalData?
    let locationMetadata: LocationMetadata?
    let origin: [LocationPair]?
    let destination: [LocationPair]?
    let reasons: [ReasonBlock]?
  }

  // MARK: Service detail

  struct ServiceDetail: Decodable {
    let scheduleMetadata: ScheduleMetadata?
    let locations: [ServiceLocationWire]?
    let origin: [LocationPair]?
    let destination: [LocationPair]?
    let reasons: [ReasonBlock]?
  }

  struct ServiceLocationWire: Decodable {
    let temporalData: TemporalData?
    let locationMetadata: LocationMetadata?
    let location: GeoLocation?
    let associatedServices: [AssociatedService]?
    let reasons: [ReasonBlock]?
  }

  // MARK: System status

  struct SystemStatusWire: Decodable {
    let rttCore: String?
    let realtimeNetworkRail: String?
  }
}

// MARK: - System status

struct SystemStatus {
  let rttCore: String?             // OK | REALTIME_DEGRADED | SCHEDULE_ONLY
  let realtimeNetworkRail: String? // OK | REALTIME_DATA_LIMITED | REALTIME_DATA_NONE

  var bannerMessage: String? {
    if rttCore == "SCHEDULE_ONLY" { return L10n.systemStatusScheduleOnly }
    if rttCore == "REALTIME_DEGRADED" { return L10n.systemStatusDegraded }
    if realtimeNetworkRail == "REALTIME_DATA_NONE" { return L10n.systemStatusDataNone }
    if realtimeNetworkRail == "REALTIME_DATA_LIMITED" { return L10n.systemStatusDataLimited }
    return nil
  }
}

// MARK: - Search (departures / arrivals)

struct DeparturesResponse {
  var services: [ServiceSummary]?
  var systemStatus: SystemStatus?

  init(services: [ServiceSummary]?, systemStatus: SystemStatus? = nil) {
    self.services = services
    self.systemStatus = systemStatus
  }
}

extension DeparturesResponse: Decodable {
  init(from decoder: Decoder) throws {
    let root = try decoder.container(keyedBy: CodingKeys.self)
    let raw = try root.decodeIfPresent([Wire.LocationLineUp].self, forKey: .services)
    services = raw?.map { ServiceSummary(lineup: $0) }
    if let ss = try root.decodeIfPresent(Wire.SystemStatusWire.self, forKey: .systemStatus) {
      systemStatus = SystemStatus(rttCore: ss.rttCore, realtimeNetworkRail: ss.realtimeNetworkRail)
    }
  }
  enum CodingKeys: String, CodingKey { case services, systemStatus }
}

struct ServiceSummary: Identifiable, Hashable {
  var id: String { "\(serviceUid ?? "")-\(runDate ?? "")" }

  let locationDetail: LocationDetail?
  let serviceUid: String?
  let runDate: String?
  let trainIdentity: String?    // headcode (trainReportingIdentity) or identity
  let atocName: String?
  let modeType: String?         // TRAIN | REPLACEMENT_BUS | BUS | SHIP | SCHEDULED_BUS
  let inPassengerService: Bool?

  fileprivate init(lineup: Wire.LocationLineUp) {
    let sm = lineup.scheduleMetadata
    serviceUid = sm?.identity
    runDate = sm?.departureDate
    trainIdentity = sm?.trainReportingIdentity ?? sm?.identity
    atocName = sm?.operator?.name
    modeType = sm?.modeType
    inPassengerService = sm?.inPassengerService
    locationDetail = LocationDetail(lineup: lineup)
  }
}

struct LocationDetail: Hashable {
  // Scheduled times (HHmm)
  let gbttBookedDeparture: String?
  let gbttBookedArrival: String?
  let passHHmm: String?           // for non-stopping pass-through trains

  // Realtime times (HHmm)
  let realtimeDeparture: String?
  let realtimeDepartureActual: Bool?
  let realtimeArrival: String?
  let realtimeArrivalActual: Bool?

  // Server-computed lateness (minutes, positive = late)
  let departureLatenessMinutes: Int?
  let arrivalLatenessMinutes: Int?

  // Realtime activation
  let realtimeActivated: Bool?

  // Live operational status
  let departureStatus: String?    // APPROACHING | AT_PLATFORM | DEPARTING | …
  let arrivalStatus: String?

  // Platform
  let platform: String?
  let platformConfirmed: Bool?
  let platformChanged: Bool?

  // Display / reason
  let displayAs: String?          // CALL | CANCELLED | DIVERTED | STARTS | TERMINATES
  let delayReason: String?        // shortText from reasons[0]

  // Metadata
  let numberOfVehicles: Int?

  // Origin / destination for row display
  let origin: [CallPointRef]?
  let destination: [CallPointRef]?

  fileprivate init(lineup: Wire.LocationLineUp) {
    let td = lineup.temporalData
    let dep = td?.departure
    let arr = td?.arrival
    let pas = td?.pass

    gbttBookedDeparture = TimeFormatting.hhmmFromISO(dep?.scheduleAdvertised)
    gbttBookedArrival = TimeFormatting.hhmmFromISO(arr?.scheduleAdvertised)
    passHHmm = TimeFormatting.hhmmFromISO(pas?.scheduleAdvertised)

    let rtDep = dep?.realtimeActual ?? dep?.realtimeForecast
    let rtArr = arr?.realtimeActual ?? arr?.realtimeForecast
    realtimeDeparture = TimeFormatting.hhmmFromISO(rtDep)
    realtimeArrival = TimeFormatting.hhmmFromISO(rtArr)
    realtimeDepartureActual = dep?.realtimeActual != nil
    realtimeArrivalActual = arr?.realtimeActual != nil
    realtimeActivated = dep?.realtimeForecast != nil || dep?.realtimeActual != nil

    departureLatenessMinutes = dep?.realtimeAdvertisedLateness
    arrivalLatenessMinutes = arr?.realtimeAdvertisedLateness

    departureStatus = dep?.status
    arrivalStatus = arr?.status

    let platformPlanned = lineup.locationMetadata?.platform?.planned
    let platformActual = lineup.locationMetadata?.platform?.actual
    platform = platformActual ?? platformPlanned
    platformConfirmed = platformActual != nil
    platformChanged = platformActual != nil && platformActual != platformPlanned

    displayAs = td?.displayAs
    delayReason = lineup.reasons?.first?.shortText

    numberOfVehicles = lineup.locationMetadata?.numberOfVehicles

    let originDesc = lineup.origin?.first?.location?.description
    origin = originDesc.map { [CallPointRef(description: $0, publicTime: nil)] }

    // destination.first.publicTime carries this station's arrival HHmm (used by the arrivals row)
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

struct ServiceAssociation: Hashable, Identifiable {
  var id: String { "\(type)-\(serviceUid ?? "")-\(runDate ?? "")" }
  let type: String       // JOIN_FROM | JOIN_INTO | DIVIDE_INTO | DIVIDE_FROM | FORM_INTO | FORM_FROM
  let isPublic: Bool
  let serviceUid: String?
  let runDate: String?
  let headcode: String?
  let operatorName: String?
}

struct ServiceDetailResponse {
  let serviceUid: String?
  let runDate: String?
  let trainIdentity: String?
  let atocName: String?
  let origin: [CallPointRef]?
  let destination: [CallPointRef]?
  let locations: [ServiceLocation]?
  let delayReason: String?
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
    delayReason = wire?.reasons?.first?.shortText

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
  let realtimeArrivalActual: Bool
  let realtimeDepartureActual: Bool
  let arrivalStatus: String?
  let departureStatus: String?
  let arrivalLatenessMinutes: Int?
  let departureLatenessMinutes: Int?
  let platform: String?
  let platformConfirmed: Bool?
  let displayAs: String?
  let isRequestStop: Bool?
  let delayReason: String?
  let associations: [ServiceAssociation]

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
    realtimeArrivalActual = td?.arrival?.realtimeActual != nil
    realtimeDepartureActual = td?.departure?.realtimeActual != nil
    arrivalStatus = td?.arrival?.status
    departureStatus = td?.departure?.status
    arrivalLatenessMinutes = td?.arrival?.realtimeAdvertisedLateness
    departureLatenessMinutes = td?.departure?.realtimeAdvertisedLateness

    let platformActual = wire.locationMetadata?.platform?.actual
    let platformPlanned = wire.locationMetadata?.platform?.planned
    platform = platformActual ?? platformPlanned
    platformConfirmed = platformActual != nil

    displayAs = td?.displayAs
    isRequestStop = wire.locationMetadata?.isRequestStop
    delayReason = wire.reasons?.first?.shortText

    associations = (wire.associatedServices ?? []).compactMap { assoc -> ServiceAssociation? in
      guard let aType = assoc.associationData?.associationType else { return nil }
      let isPublic = assoc.associationData?.isPublic ?? true
      let sm = assoc.scheduleMetadata
      return ServiceAssociation(
        type: aType,
        isPublic: isPublic,
        serviceUid: sm?.identity,
        runDate: sm?.departureDate,
        headcode: sm?.trainReportingIdentity ?? sm?.identity,
        operatorName: sm?.operator?.name
      )
    }
  }
}
