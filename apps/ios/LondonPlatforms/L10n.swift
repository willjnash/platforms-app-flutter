import Foundation

/// Centralized localized strings (see [Localizable.xcstrings](Localizable.xcstrings)).
enum L10n {
  // MARK: - Tabs
  static var tabBoard: String { String(localized: "tab_board") }
  static var tabSettings: String { String(localized: "tab_settings") }

  // MARK: - Board
  static var departures: String { String(localized: "departures") }
  static var arrivals: String { String(localized: "arrivals") }
  static var boardPickerAccessibility: String { String(localized: "board_picker_a11y") }
  static var boardSection: String { String(localized: "board_section") }

  static var scheduleLiveDepartures: String { String(localized: "schedule_live_departures") }
  static var scheduleLiveArrivals: String { String(localized: "schedule_live_arrivals") }
  static func scheduleForTimeToday(_ time: String) -> String {
    String(format: String(localized: "schedule_for_time_format"), time)
  }

  static func lastUpdated(at time: String) -> String {
    String(format: String(localized: "last_updated_format"), time)
  }

  static var refresh: String { String(localized: "refresh") }
  static var changeStation: String { String(localized: "change_station") }
  static var menuTimeFilter: String { String(localized: "menu_time_filter") }

  static var sectionDepartures: String { String(localized: "section_departures") }
  static var sectionArrivals: String { String(localized: "section_arrivals") }

  static var noServicesTitle: String { String(localized: "no_services_title") }
  static var noServicesDescription: String { String(localized: "no_services_description") }

  // MARK: - Live indicator
  static var liveLabel: String { String(localized: "live_label") }
  static var liveA11y: String { String(localized: "live_a11y") }

  // MARK: - Status badges
  static var statusOnTime: String { String(localized: "status_on_time") }
  static func statusDelayed(_ minutes: Int) -> String {
    String(format: String(localized: "status_delayed_format"), minutes)
  }
  static var statusCancelled: String { String(localized: "status_cancelled") }

  // MARK: - Stations
  static var stationTitle: String { String(localized: "station_title") }
  static var stationsTitle: String { String(localized: "stations_title") }

  // MARK: - Time filter
  static var timeFilterTitle: String { String(localized: "time_filter_title") }
  static var timePickerLabel: String { String(localized: "time_picker_label") }
  static var timeFilterFooter: String { String(localized: "time_filter_footer") }
  static var clearFilter: String { String(localized: "clear_filter") }
  static var cancel: String { String(localized: "cancel") }
  static var apply: String { String(localized: "apply") }

  // MARK: - Service detail
  static var serviceNavTitle: String { String(localized: "service_nav_title") }
  static var loading: String { String(localized: "loading") }
  static var couldNotLoadService: String { String(localized: "could_not_load_service") }
  static var noData: String { String(localized: "no_data") }
  static var pullToRefreshHint: String { String(localized: "pull_to_refresh_hint") }
  static var done: String { String(localized: "done") }

  static var headcode: String { String(localized: "headcode") }
  static var trainOperator: String { String(localized: "train_operator") }
  static var callingPoints: String { String(localized: "calling_points") }
  static var noCallingPoints: String { String(localized: "no_calling_points") }
  static func callingPointToward(_ destination: String) -> String {
    String(format: String(localized: "calling_point_toward_format"), destination)
  }
  static func callingPointRowAccessibility(station: String, time: String, toward: String?) -> String {
    let base = String(format: String(localized: "calling_point_row_a11y_format"), station, time)
    guard let toward else { return base }
    return base + ". " + String(format: String(localized: "calling_point_row_a11y_continues_format"), toward)
  }

  // MARK: - Platform
  static func platformConfirmedA11y(_ platform: String) -> String {
    String(format: String(localized: "platform_confirmed_a11y_format"), platform)
  }
  static func platformPendingA11y(_ platform: String) -> String {
    String(format: String(localized: "platform_pending_a11y_format"), platform)
  }
  static var platformChangedA11y: String { String(localized: "platform_changed_a11y") }
  static var changedBadge: String { String(localized: "changed_badge") }
  static func delayA11y(_ minutes: Int) -> String {
    String(format: String(localized: "delay_a11y_format"), minutes)
  }
  static var emDash: String { String(localized: "em_dash") }

  // MARK: - Arrivals a11y
  static func arrivalRowA11y(time: String, origin: String, operatorName: String, platform: String) -> String {
    String(format: String(localized: "arrival_row_a11y_format"), time, origin, operatorName, platform)
  }

  // MARK: - Settings / About
  static var aboutSection: String { String(localized: "about_section") }
  static var aboutAttribution: String { String(localized: "about_attribution") }
  static var aboutFeedbackWelcome: String { String(localized: "about_feedback_welcome") }
  static var emailFeedback: String { String(localized: "email_feedback") }
  static var privacyPolicy: String { String(localized: "privacy_policy") }
  static var versionLabel: String { String(localized: "version_label") }

  // MARK: - Errors
  static var rttMissingCredentials: String { String(localized: "rtt_error_missing_credentials") }
  static var rttInvalidURL: String { String(localized: "rtt_error_invalid_url") }
  static func rttHTTPStatus(_ code: Int) -> String {
    String(format: String(localized: "rtt_error_http_format"), code)
  }
  static var rttDecoding: String { String(localized: "rtt_error_decoding") }
}
