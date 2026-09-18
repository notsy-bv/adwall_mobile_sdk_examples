import MembranaAdWallSDK
import SwiftUI
import UIKit

/// The App ID Membrana supplies for your application. This example uses Membrana's standard
/// example configuration, which shows the wall with a close control.
///
/// A second example configuration is available if you want to see a rewarded-only wall, where the
/// only way past the gate is to watch the rewarded ad. To try it, comment the line below and
/// uncomment the alternative.
private let demoAppID = "membrana-media-example"
// private let demoAppID = "membrana-media-example-rewarded-only"

@main
struct DemoSwiftUIApp: App {
    @StateObject private var model = SwiftUIDemoModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ScenarioListView(model: model)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

@MainActor
final class SwiftUIDemoModel: NSObject, ObservableObject, MembranaAdWallDelegate {
    let adWall = SwiftUIDemoModel.makeAdWall()

    private static func makeAdWall() -> MembranaAdWall {
        // Publisher integration step 1: create one application-scoped SDK instance with the App ID
        // Membrana supplies for your application, retain it for the lifetime of the app, and pass
        // that same instance to every screen you gate. Do not create a second instance per screen.
        let adWall = MembranaAdWall(appId: demoAppID)

        // Optional test integration. While integrating, you can run the SDK against Google's
        // dedicated test ad units and a capping ledger isolated from production, so no real
        // inventory is requested and your production capping history is untouched. Uncomment the
        // block below to enable it.
        //
        // Remove or disable this call before shipping to production: it changes ad configuration
        // and capping behavior, and suppresses analytics delivery by default. The SDK does not
        // prevent enabling it in a distributed app.
        //
        // do {
        //     try adWall.enableIntegrationTesting(
        //         options: MembranaAdWallIntegrationTestOptions(
        //             ads: .googleTestAds,
        //             capping: .disabled
        //         )
        //     )
        // } catch {
        //     assertionFailure("Unable to enable AdWall integration testing: \(error)")
        // }

        return adWall
    }

    @Published var isReady = false
    @Published var status = "Preparing MembranaAdWall"

    override init() {
        super.init()
        Task { @MainActor in
            do {
                // Publisher integration step 2: after the host app has completed its own
                // privacy/consent flow and permits ad requests, call start() exactly once from the
                // application root. Startup runs asynchronously, so it must not block navigation;
                // screens may open while settings and ads are still being prepared.
                try await adWall.start()
                isReady = true
                status = "MembranaAdWall ready"
            } catch {
                status = error.localizedDescription
            }
        }
    }

    func adWallDidUnlockContent(_ adWall: MembranaAdWall) {
        // Publisher integration step 5: grant access only from the SDK's unlock callback.
        status = "Content unlocked"
    }

    func adWallDidRejectContent(_ adWall: MembranaAdWall) {
        // Keep content protected or install the publisher's fallback when access is not earned.
        status = "Publisher handled rejection"
    }

    func adWall(
        _ adWall: MembranaAdWall,
        contentUnavailableWithReason reason: MembranaAdWallUnavailableReason
    ) {
        // Capping and no-fill are expected production states. Keep premium content protected and
        // expose the publisher's own login, subscription, or retry path.
        status = "No wall available; publisher fallback applied"
    }

    func adWall(_ adWall: MembranaAdWall, didFailWithError error: NSError) {
        // Send technical failures to the publisher's diagnostics before showing an app-owned
        // fallback. Do not unlock content from this callback.
        status = "Ad error; publisher fallback applied"
    }
}

private enum SwiftUIGateScope: CaseIterable, Identifiable {
    case wholePage
    case partialPage
    /// Same whole-page coverage as `wholePage`; only the wall's styling differs.
    case brandedAppearance

    var id: Self { self }

    var title: String {
        switch self {
        case .wholePage: return "Whole page"
        case .partialPage: return "Part of screen"
        case .brandedAppearance: return "Branded styling"
        }
    }

    var detail: String {
        switch self {
        case .wholePage: return "Protect the complete article from the first frame"
        case .partialPage: return "Keep the introduction visible and gate the remaining article"
        case .brandedAppearance: return "Same whole-page coverage, restyled with publisher colors and fonts"
        }
    }

    var symbol: String {
        switch self {
        case .wholePage: return "rectangle.fill"
        case .partialPage: return "rectangle.split.2x1"
        case .brandedAppearance: return "paintpalette"
        }
    }

    var coversWholePage: Bool {
        self != .partialPage
    }

    /// Remote settings always own the wall's text and logo. An appearance only restyles how that
    /// content is drawn, so a publisher can match the card to its own design language. Returning
    /// `nil` leaves the SDK's own look in place.
    var appearance: MembranaAdWallAppearance? {
        guard self == .brandedAppearance else { return nil }
        return MembranaAdWallAppearance(
            buttonBackgroundColor: .systemPink,
            buttonForegroundColor: .white,
            titleFont: UIFont(name: "AvenirNext-Bold", size: 22),
            descriptionFont: UIFont(name: "AvenirNext-Regular", size: 17),
            buttonFont: UIFont(name: "AvenirNext-DemiBold", size: 17)
        )
    }
}

private struct ScenarioListView: View {
    @ObservedObject var model: SwiftUIDemoModel

    var body: some View {
        List(SwiftUIGateScope.allCases) { scope in
            NavigationLink(
                destination: SwiftUIArticleView(
                    article: DemoContent.article,
                    model: model,
                    gateScope: scope
                )
            ) {
                Label {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(scope.title)
                            .font(.headline)
                        Text(scope.detail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: scope.symbol)
                        .font(.title2)
                        .foregroundColor(.pink)
                        .frame(width: 34)
                }
                .padding(.vertical, 10)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("AdWall Scenarios")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: model.isReady ? "checkmark.circle.fill" : "clock")
                    .foregroundColor(model.isReady ? .green : .secondary)
                    .accessibilityLabel(model.status)
            }
        }
    }
}

private struct SwiftUIArticleView: View {
    let article: DemoArticle
    @ObservedObject var model: SwiftUIDemoModel
    let gateScope: SwiftUIGateScope

    var body: some View {
        Group {
            if gateScope.coversWholePage {
                articleScrollView
                    .if(model.isReady) { articleView in
                        // Publisher integration steps 3–4: build the protected content first, then
                        // attach the SwiftUI gate to the exact view region that must remain locked.
                        articleView.membranaAdWallGate(
                            using: model.adWall,
                            appearance: gateScope.appearance,
                            delegate: model
                        )
                    }
            } else {
                articleScrollView
            }
        }
        .navigationTitle(gateScope.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var articleScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                articleHeader

                if let introduction = article.paragraphs.first {
                    Text(introduction)
                        .font(.body)
                }

                protectedTail
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 48)
        }
    }

    private var articleHeader: some View {
        Group {
            Text(article.category)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(article.color))
            Text(article.title)
                .font(.title.weight(.bold))
            Text(article.summary)
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }

    private var protectedTail: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                Color(article.color)
                Image(systemName: article.symbolName)
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(height: 180)
            .cornerRadius(12)

            ForEach(Array(article.paragraphs.dropFirst().enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .if(gateScope == .partialPage && model.isReady) { articleTail in
            // The modifier may protect a subtree instead of the complete screen.
            articleTail.membranaAdWallGate(
                using: model.adWall,
                delegate: model
            )
        }
    }

}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
