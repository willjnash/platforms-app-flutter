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

  // MARK: - API requests

  func fetchBoard(crs: String, arrivals: Bool, timeHHmm: String?) async throws -> DeparturesResponse {
    let url = try locationURL(crs: crs, timeHHmm: timeHHmm)
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

  // MARK: - URL helpers

  private func locationURL(crs: String, timeHHmm: String?) throws -> URL {
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
    components.queryItems = items
    guard let url = components.url else { throw RTTError.invalidURL }
    return url
  }
}
