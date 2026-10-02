import SwiftUI

/// Privacy and support, inside the app. App Review guideline 5.1.1(i) wants the privacy policy reachable
/// in the app, and 1.5 wants a way to contact the developer. The full policy is here as text, so it
/// works with no network; the link is the canonical web copy.
///
/// Keep this in step with site/privacy.html; they are the same statement in two places.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    static let supportEmail = "noah@nsgsolutions.co"
    static let policyURL = URL(string: "https://nsgnoah.github.io/sweetspot/privacy.html")!
    static let supportURL = URL(string: "https://nsgnoah.github.io/sweetspot/")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    card("Privacy") {
                        section("The short version",
                                "Venn has no accounts, no ads, no analytics, and no tracking. It never connects to the internet, so nothing you do in it is sent to us or anyone else.")
                        section("What stays on this device",
                                "Your progress on each puzzle, and whether you\u{2019}ve seen How to play, are saved in the app on this device. Start over clears a puzzle. Deleting the app clears everything.")
                        section("Sharing",
                                "Share and Copy hand your result, the puzzle number and your \u{25CF} \u{25D0} \u{25CB} marks, to the share sheet or clipboard only when you tap them. Where it goes from there is up to you.")
                        section("Children",
                                "Venn collects nothing from anyone, children included.")
                        Link("Read the policy on the web", destination: Self.policyURL)
                            .font(.subheadline.weight(.semibold))
                    }

                    card("Support") {
                        Text("Questions, bugs, or a puzzle answer you think is wrong? Get in touch.")
                        Link(Self.supportEmail, destination: URL(string: "mailto:\(Self.supportEmail)?subject=Venn")!)
                            .font(.body.weight(.semibold))
                        Link("Support page", destination: Self.supportURL)
                            .font(.subheadline.weight(.semibold))
                    }

                    Text("Version \(version)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(16)
            }
            .background(Theme.ground)
            .navigationTitle("Privacy & support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.display(22))
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.chip))
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
