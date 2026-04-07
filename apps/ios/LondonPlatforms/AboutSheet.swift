import SwiftUI

struct AboutSheet: View {
  @Environment(\.dismiss) private var dismiss

  private let privacyURL = URL(string: "https://platformsapp.wordpress.com/london-platforms-privacy-notice/")!
  private let feedbackURL = URL(string: "mailto:platformfeedback@icloud.com")!

  var body: some View {
    NavigationStack {
      List {
        Section {
          Text(L10n.aboutAttribution)
          Text(L10n.aboutFeedbackWelcome)
        }

        Section {
          Link(destination: feedbackURL) {
            Label(L10n.emailFeedback, systemImage: "envelope")
          }
          Link(destination: privacyURL) {
            Label(L10n.privacyPolicy, systemImage: "hand.raised")
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle(L10n.londonPlatforms)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(L10n.done) { dismiss() }
            .fontWeight(.semibold)
        }
      }
    }
    .presentationDragIndicator(.visible)
  }
}
