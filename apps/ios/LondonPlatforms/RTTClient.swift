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

/// HTTP client for `https://api.rtt.io` (SERVICE_SPEC §3).
final class RTTClient {
  static let shared = RTTClient()

  private let baseURL = URL(string: "https://api.rtt.io")!
  private let session: URLSession
  private let jsonDecoder: JSONDecoder

  private init() {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    session = URLSession(configuration: config)
    jsonDecoder = JSONDecoder()
  }

  private func authorizationValue() throws -> String {
    guard
      let raw = Bundle.main.object(forInfoDictionaryKey: "RTTBasicAuthHeader") as? String,
      !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      throw RTTError.missingCredentials
    }
    return raw.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Search path per SERVICE_SPEC §3.3–3.4.
  private func searchURL(crs: String, arrivals: Bool, timeHHmm: String?) throws -> URL {
    let upper = crs.uppercased()
    var path = "/api/v1/json/search/\(upper)"
    if let timeHHmm, !timeHHmm.isEmpty {
      let cal = Calendar.current
      let comps = cal.dateComponents(in: TimeZone.current, from: Date())
      guard let y = comps.year, let m = comps.month, let d = comps.day else {
        throw RTTError.invalidURL
      }
      let mm = String(format: "%02d", m)
      let dd = String(format: "%02d", d)
      path += "/\(y)/\(mm)/\(dd)/\(timeHHmm)"
    }
    if arrivals {
      path += "/arrivals"
    }
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
    components.path = path
    guard let url = components.url else { throw RTTError.invalidURL }
    return url
  }

  func fetchBoard(crs: String, arrivals: Bool, timeHHmm: String?) async throws -> DeparturesResponse {
    let url = try searchURL(crs: crs, arrivals: arrivals, timeHHmm: timeHHmm)
    var request = URLRequest(url: url)
    request.setValue(try authorizationValue(), forHTTPHeaderField: "Authorization")
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw RTTError.httpStatus(-1)
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
    let segment = TimeFormatting.serviceDatePathSegment(runDate)
    guard !segment.isEmpty else { throw RTTError.invalidURL }
    let encodedUid =
      serviceUid.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? serviceUid
    let path = "/api/v1/json/service/\(encodedUid)\(segment)"
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
    components.path = path
    guard let url = components.url else { throw RTTError.invalidURL }
    var request = URLRequest(url: url)
    request.setValue(try authorizationValue(), forHTTPHeaderField: "Authorization")
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
}
