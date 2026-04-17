import Foundation

enum RTTError: LocalizedError {
  case missingCredentials
  case invalidURL
  case httpStatus(Int)
  case decoding(Error)

  var errorDescription: String? {
    switch self {
    case .missingCredentials:
      return L10n.rttMissingCredentials
    case .invalidURL:
      return L10n.rttInvalidURL
    case .httpStatus(let code):
      return L10n.rttHTTPStatus(code)
    case .decoding:
      return L10n.rttDecoding
    }
  }
}

/// HTTP client for `https://data.rtt.io` (RTT API v2).
///
/// Authentication uses a two-token flow:
///  - `RTTBearerToken` in Info.plist is the long-lived **refresh token**.
///  - Before each request the client exchanges it for a short-lived access
///    token via `GET /api/get_access_token`, caching the result until it is
///    within 60 seconds of expiry.
final class RTTClient {
  static let shared = RTTClient()

  private let baseURL = URL(string: "https://data.rtt.io")!
  private let session: URLSession
  private let jsonDecoder: JSONDecoder

  // Cached short-lived access token
  private var cachedAccessToken: String?
  private var accessTokenExpiry: Date?

  private init() {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    session = URLSession(configuration: config)
    jsonDecoder = JSONDecoder()
  }

  // MARK: - Token management

  private func refreshToken() throws -> String {
    guard
      let raw = Bundle.main.object(forInfoDictionaryKey: "RTTBearerToken") as? String,
      !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      throw RTTError.missingCredentials
    }
    return raw.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Returns a valid short-lived access token, refreshing if expired.
  private func accessToken() async throws -> String {
    if let token = cachedAccessToken,
       let expiry = accessTokenExpiry,
       expiry.timeIntervalSinceNow > 60 {
      return token
    }

    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
    components.path = "/api/get_access_token"
    guard let url = components.url else { throw RTTError.invalidURL }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(try refreshToken())", forHTTPHeaderField: "Authorization")

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw RTTError.missingCredentials
    }

    struct TokenResponse: Decodable {
      let token: String
      let validUntil: String
    }
    let tokenResp = try jsonDecoder.decode(TokenResponse.self, from: data)
    cachedAccessToken = tokenResp.token
    accessTokenExpiry = Self.isoParser.date(from: tokenResp.validUntil)
    return tokenResp.token
  }

  private static let isoParser: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
    return f
  }()

  // MARK: - Board

  func fetchBoard(
    crs: String,
    arrivals: Bool,
    timeHHmm: String?,
    filterToCRS: String? = nil
  ) async throws -> DeparturesResponse {
    let url = try locationURL(crs: crs, timeHHmm: timeHHmm, filterToCRS: filterToCRS)
    var request = URLRequest(url: url)
    request.setValue("Bearer \(try await accessToken())", forHTTPHeaderField: "Authorization")
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw RTTError.httpStatus(-1)
    }
    if http.statusCode == 204 {
      return DeparturesResponse(services: [])
    }
    guard http.statusCode == 200 else {
      throw RTTError.httpStatus(http.statusCode)
    }
    do {
      return try jsonDecoder.decode(DeparturesResponse.self, from: data)
    } catch {
      throw RTTError.decoding(error)
    }
  }

  // MARK: - Service detail

  func fetchServiceDetail(serviceUid: String, runDate: String) async throws -> ServiceDetailResponse {
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
    components.path = "/gb-nr/service"
    components.queryItems = [
      URLQueryItem(name: "identity", value: serviceUid),
      URLQueryItem(name: "departureDate", value: runDate),
    ]
    guard let url = components.url else { throw RTTError.invalidURL }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(try await accessToken())", forHTTPHeaderField: "Authorization")
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw RTTError.httpStatus(-1)
    }
    guard http.statusCode == 200 else {
      throw RTTError.httpStatus(http.statusCode)
    }
    do {
      return try jsonDecoder.decode(ServiceDetailResponse.self, from: data)
    } catch {
      throw RTTError.decoding(error)
    }
  }

  // MARK: - Station catalog

  /// Fetches all UK passenger stops and caches them in `StationCatalog`.
  func fetchAndCacheStops() async {
    guard let url = URL(string: "https://data.rtt.io/data/stops") else { return }
    guard let token = try? await accessToken() else { return }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    guard let (data, response) = try? await session.data(for: request),
          (response as? HTTPURLResponse)?.statusCode == 200 else { return }

    struct StopsResponse: Decodable {
      struct Stop: Decodable {
        let description: String?
        let shortCode: String?
        let latitude: Double?
        let longitude: Double?

        private enum CodingKeys: String, CodingKey {
          case description
          case shortCode
          case latitude
          case longitude
          case lat
          case lon
        }

        init(from decoder: Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          description = try container.decodeIfPresent(String.self, forKey: .description)
          shortCode = try container.decodeIfPresent(String.self, forKey: .shortCode)
          latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
            ?? container.decodeIfPresent(Double.self, forKey: .lat)
          longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
            ?? container.decodeIfPresent(Double.self, forKey: .lon)
        }
      }
      let stops: [Stop]
    }
    guard let parsed = try? jsonDecoder.decode(StopsResponse.self, from: data) else { return }
    let stations = parsed.stops.compactMap { stop -> Station? in
      guard let crs = stop.shortCode, !crs.isEmpty,
            let name = stop.description, !name.isEmpty else { return nil }
      return Station(
        crs: crs,
        displayName: name,
        latitude: stop.latitude,
        longitude: stop.longitude
      )
    }
    .sorted { $0.displayName < $1.displayName }
    StationCatalog.updateCache(stations)
  }

  // MARK: - URL helpers

  private func locationURL(crs: String, timeHHmm: String?, filterToCRS: String?) throws -> URL {
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
    components.path = "/gb-nr/location"
    var items: [URLQueryItem] = [URLQueryItem(name: "code", value: crs.uppercased())]
    if let timeHHmm, !timeHHmm.isEmpty {
      let cal = Calendar.current
      let comps = cal.dateComponents(in: TimeZone.current, from: Date())
      guard let y = comps.year, let m = comps.month, let d = comps.day else {
        throw RTTError.invalidURL
      }
      let hh = String(timeHHmm.prefix(2))
      let mm = String(timeHHmm.dropFirst(2).prefix(2))
      let timeFrom = String(format: "%04d-%02d-%02dT%@:%@:00", y, m, d, hh, mm)
      items.append(URLQueryItem(name: "timeFrom", value: timeFrom))
    }
    if let filterToCRS, !filterToCRS.isEmpty {
      items.append(URLQueryItem(name: "filterTo", value: filterToCRS.uppercased()))
    }
    components.queryItems = items
    guard let url = components.url else { throw RTTError.invalidURL }
    return url
  }
}
