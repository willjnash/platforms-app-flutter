import Foundation

/// Centralized localized strings (see [Localizable.xcstrings](Localizable.xcstrings)).
enum L10n {
  static var departures: String { String(localized: "departures") }
  static var arrivals: String { String(localized: "arrivals") }
  static var boardPickerAccessibility: String { String(localized: "board_picker_a11y") }

  static var scheduleLiveDepartures: String { String(localized: "schedule_live_departures") }
  static var scheduleLiveArrivals: String { String(localized: "schedule_live_arrivals") }
  static func scheduleForTimeToday(_ time: String) -> String {
    String(format: String(localized: "schedule_for_time_format"), time)
  }

  static func lastUpdated(at time: String) -> String {
    String(format: String(localized: "last_updated_format"), time)
  }

  static var refresh: String { String(localized: "refresh") }
  static var moreMenu: String { String(localized: "more_menu") }
  static var menuStation: String { String(localized: "menu_station") }
  static var menuTimeFilter: String { String(localized: "menu_time_filter") }
  static var menuAbout: String { String(localized: "menu_about") }

  static var sectionDepartures: String { String(localized: "section_departures") }
  static var sectionArrivals: String { String(localized: "section_arrivals") }

  static var noServicesTitle: String { String(localized: "no_services_title") }
  static var noServicesDescription: String { String(localized: "no_services_description") }

  static var selectTrainTitle: String { String(localized: "select_train_title") }
  static var selectTrainDescription: String { String(localized: "select_train_description") }

  static var aboutAttribution: String { String(localized: "about_attribution") }
  static var aboutFeedbackWelcome: String { String(localized: "about_feedback_welcome") }
  static var emailFeedback: String { String(localized: "email_feedback") }
  static var privacyPolicy: String { String(localized: "privacy_policy") }
  static var londonPlatforms: String { String(localized: "london_platforms") }
  static var done: String { String(localized: "done") }

  static var timeFilterTitle: String { String(localized: "time_filter_title") }
  static var timePickerLabel: String { String(localized: "time_picker_label") }
  static var timeFilterFooter: String { String(localized: "time_filter_footer") }
  static var clearFilter: String { String(localized: "clear_filter") }
  static var cancel: String { String(localized: "cancel") }
  static var apply: String { String(localized: "apply") }

  static var stationTitle: String { String(localized: "station_title") }

  static var serviceNavTitle: String { String(localized: "service_nav_title") }
  static var loading: String { String(localized: "loading") }
  static var couldNotLoadService: String { String(localized: "could_not_load_service") }
  static var noData: String { String(localized: "no_data") }
  static var pullToRefreshHint: String { String(localized: "pull_to_refresh_hint") }

  static var headcode: String { String(localized: "headcode") }
  static var trainOperator: String { String(localized: "train_operator") }
  static var routeSection: String { String(localized: "route_section") }
  static var callingPoints: String { String(localized: "calling_points") }
  static var noCallingPoints: String { String(localized: "no_calling_points") }
  static func callingPointToward(_ destination: String) -> String {
    String(format: String(localized: "calling_point_toward_format"), destination)
  }
  /// VoiceOver for a calling point row (station + time; optional continuation).
  static func callingPointRowAccessibility(station: String, time: String, toward: String?) -> String {
    let base = String(format: String(localized: "calling_point_row_a11y_format"), station, time)
    guard let toward else { return base }
    return base + ". " + String(format: String(localized: "calling_point_row_a11y_continues_format"), toward)
  }

  static var platformUnknown: String { String(localized: "platform_unknown") }
  static func platformConfirmedA11y(_ platform: String) -> String {
    String(format: String(localized: "platform_confirmed_a11y_format"), platform)
  }

  static func departureSubtitleConfirmed(operatorName: String) -> String {
    String(
      format: String(localized: "departure_subtitle_confirmed_format"),
      operatorName
    )
  }
  static func departureSubtitlePending(operatorName: String, platform: String) -> String {
    String(
      format: String(localized: "departure_subtitle_pending_format"),
      operatorName,
      platform
    )
  }

  static var emDash: String { String(localized: "em_dash") }

  static var changedBadge: String { String(localized: "changed_badge") }
  static var platformChangedA11y: String { String(localized: "platform_changed_a11y") }
  static func delayA11y(_ minutes: Int) -> String {
    String(format: String(localized: "delay_a11y_format"), minutes)
  }

  static func arrivalRowA11y(time: String, origin: String, operatorName: String, platform: String) -> String {
    String(
      format: String(localized: "arrival_row_a11y_format"),
      time,
      origin,
      operatorName,
      platform
    )
  }

  static func arrivalRowA11yNoPlatform(time: String, origin: String, operatorName: String) -> String {
    String(
      format: String(localized: "arrival_row_a11y_no_platform_format"),
      time,
      origin,
      operatorName
    )
  }

  static var boardSection: String { String(localized: "board_section") }

  static var rttMissingCredentials: String { String(localized: "rtt_error_missing_credentials") }
  static var rttInvalidURL: String { String(localized: "rtt_error_invalid_url") }
  static func rttHTTPStatus(_ code: Int) -> String {
    String(format: String(localized: "rtt_error_http_format"), code)
  }
  static var rttDecoding: String { String(localized: "rtt_error_decoding") }
}
