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
  static var statusPassThrough: String { String(localized: "status_pass_through") }

  // MARK: - Live operational status
  static var statusApproaching: String { String(localized: "status_approaching") }
  static var statusArriving: String { String(localized: "status_arriving") }
  static var statusAtPlatform: String { String(localized: "status_at_platform") }
  static var statusDeparting: String { String(localized: "status_departing") }
  static var statusDepartPreparing: String { String(localized: "status_depart_preparing") }
  static var statusDepartReady: String { String(localized: "status_depart_ready") }

  // MARK: - System status banner
  static var systemStatusDegraded: String { String(localized: "system_status_degraded") }
  static var systemStatusScheduleOnly: String { String(localized: "system_status_schedule_only") }
  static var systemStatusDataNone: String { String(localized: "system_status_data_none") }
  static var systemStatusDataLimited: String { String(localized: "system_status_data_limited") }

  // MARK: - Bus replacement
  static var busReplacementBadge: String { String(localized: "bus_replacement_badge") }

  // MARK: - Filter menu
  static var filterMenuLabel: String { String(localized: "filter_menu_label") }
  static var filterByDestination: String { String(localized: "filter_by_destination") }
  static var filterByTime: String { String(localized: "filter_by_time") }
  static var clearFilters: String { String(localized: "clear_filters") }
  static func activeFilterTowards(_ crs: String) -> String {
    String(format: String(localized: "active_filter_towards_format"), crs)
  }
  static func activeFilterTime(_ time: String) -> String {
    String(format: String(localized: "active_filter_time_format"), time)
  }

  // MARK: - Towards filter
  static var towardsFilterTitle: String { String(localized: "towards_filter_title") }
  static var towardsFilterAccessibility: String { String(localized: "towards_filter_a11y") }
  static var clearTowardsFilter: String { String(localized: "clear_towards_filter") }

  // MARK: - Stations
  static var stationTitle: String { String(localized: "station_title") }
  static var stationsTitle: String { String(localized: "stations_title") }
  static var stationNearMeSection: String {
    String(localized: "station_near_me_section", defaultValue: "Near Me")
  }
  static var stationNearMeAction: String {
    String(localized: "station_near_me_action", defaultValue: "Find nearby stations")
  }
  static var stationNearMeDenied: String {
    String(
      localized: "station_near_me_denied",
      defaultValue: "Location access is off. Enable it in Settings to find nearby stations."
    )
  }
  static var stationNearMeRestricted: String {
    String(
      localized: "station_near_me_restricted",
      defaultValue: "Location is restricted on this device."
    )
  }
  static var stationNearMeUnavailable: String {
    String(
      localized: "station_near_me_unavailable",
      defaultValue: "Could not get your current location."
    )
  }
  static var stationNearMeDistanceMeters: String {
    String(localized: "station_near_me_distance_meters", defaultValue: "%d m away")
  }
  static var stationNearMeDistanceKilometers: String {
    String(localized: "station_near_me_distance_kilometers", defaultValue: "%.1f km away")
  }

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
  static var delayReasonLabel: String { String(localized: "delay_reason_label") }
  static var callingPoints: String { String(localized: "calling_points") }
  static var noCallingPoints: String { String(localized: "no_calling_points") }
  static func callingPointToward(_ destination: String) -> String {
    String(format: String(localized: "calling_point_toward_format"), destination)
  }
  static func callingPointRowAccessibility(station: String, time: String, toward: String?) -> String {
    callingPointRowAccessibility(station: station, time: time, toward: toward, progress: nil)
  }

  static func callingPointRowAccessibility(
    station: String,
    time: String,
    toward: String?,
    progress: CallingPointProgress?
  ) -> String {
    var base = String(format: String(localized: "calling_point_row_a11y_format"), station, time)
    if let toward {
      base += ". " + String(format: String(localized: "calling_point_row_a11y_continues_format"), toward)
    }
    if let progress, let phrase = CallingPointProgress.accessibilityPhrase(for: progress) {
      base += ". " + phrase
    }
    return base
  }

  static var callingPointProgressNext: String { String(localized: "calling_point_progress_next") }
  static var callingPointHere: String { String(localized: "calling_point_here") }
  static var callingPointProgressPassedA11y: String { String(localized: "calling_point_progress_passed_a11y") }
  static var callingPointProgressCurrentA11y: String { String(localized: "calling_point_progress_current_a11y") }
  static var callingPointProgressNextA11y: String { String(localized: "calling_point_progress_next_a11y") }

  // MARK: - Request stop
  static var requestStopBadge: String { String(localized: "request_stop_badge") }

  // MARK: - Associations
  static var associationsSection: String { String(localized: "associations_section") }
  static func associationJoinFrom(_ headcode: String) -> String {
    String(format: String(localized: "association_join_from_format"), headcode)
  }
  static func associationJoinInto(_ headcode: String) -> String {
    String(format: String(localized: "association_join_into_format"), headcode)
  }
  static func associationDivideInto(_ headcode: String) -> String {
    String(format: String(localized: "association_divide_into_format"), headcode)
  }
  static func associationDivideFrom(_ headcode: String) -> String {
    String(format: String(localized: "association_divide_from_format"), headcode)
  }
  static func associationFormInto(_ headcode: String) -> String {
    String(format: String(localized: "association_form_into_format"), headcode)
  }
  static func associationFormFrom(_ headcode: String) -> String {
    String(format: String(localized: "association_form_from_format"), headcode)
  }

  // MARK: - Vehicle count
  static func vehiclesFormat(_ count: Int) -> String {
    String(format: String(localized: "vehicles_format"), count)
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
  static var platformConfidenceChanged: String {
    String(localized: "platform_confidence_changed", defaultValue: "Platform changed")
  }
  static var platformConfidenceConfirmed: String {
    String(localized: "platform_confidence_confirmed", defaultValue: "Platform confirmed")
  }
  static var platformConfidenceExpected: String {
    String(localized: "platform_confidence_expected", defaultValue: "Expected platform")
  }
  static var platformConfidencePending: String {
    String(localized: "platform_confidence_pending", defaultValue: "Confirmation soon")
  }
  static var platformConfidenceUnavailable: String {
    String(localized: "platform_confidence_unavailable", defaultValue: "Platform not yet available")
  }
  static func delayA11y(_ minutes: Int) -> String {
    String(format: String(localized: "delay_a11y_format"), minutes)
  }
  static var emDash: String { String(localized: "em_dash") }

  // MARK: - Arrivals a11y
  static func arrivalRowA11y(time: String, origin: String, operatorName: String, platform: String) -> String {
    String(format: String(localized: "arrival_row_a11y_format"), time, origin, operatorName, platform)
  }

  // MARK: - Settings
  static var boardPreferencesSection: String { String(localized: "board_preferences_section") }
  static var showNonStoppingTrains: String { String(localized: "show_non_stopping_trains") }
  static var showNonStoppingTrainsFooter: String { String(localized: "show_non_stopping_trains_footer") }
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
