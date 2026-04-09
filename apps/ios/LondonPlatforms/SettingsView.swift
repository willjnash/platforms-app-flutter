import SwiftUI

struct SettingsView: View {
  private let privacyURL = URL(string: "https://platformsapp.wordpress.com/london-platforms-privacy-notice/")!
  private let feedbackURL = URL(string: "mailto:platformfeedback@icloud.com")!

  var body: some View {
    List {
      Section {
        Text(L10n.aboutAttribution)
        Text(L10n.aboutFeedbackWelcome)
      } header: {
        Text(L10n.aboutSection)
      }

      Section {
        Link(destination: feedbackURL) {
          Label(L10n.emailFeedback, systemImage: "envelope")
        }
        Link(destination: privacyURL) {
          Label(L10n.privacyPolicy, systemImage: "hand.raised")
        }
      }

      Section {
        LabeledContent(L10n.versionLabel) {
          Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            .foregroundStyle(.secondary)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle(L10n.tabSettings)
    .navigationBarTitleDisplayMode(.large)
  }
}
