import MembranaAdWallSDK
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
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let adWall = AppDelegate.makeAdWall()

    @MainActor
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

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let scenarioList = ScenarioListViewController(adWall: adWall)
        let scenarios = UINavigationController(rootViewController: scenarioList)
        scenarios.tabBarItem = UITabBarItem(title: "Today", image: UIImage(systemName: "newspaper"), tag: 0)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = scenarios
        window.makeKeyAndVisible()
        self.window = window

        // Publisher diagnostics: enable detailed SDK messages before start() while integrating.
        // View them in Xcode's debug console and filter for subsystem
        // "media.membrana.adwall.sdk". Keep the default `.error` level in production unless
        // broader diagnostics are intentionally required.
        #if DEBUG
        adWall.logLevel = .debug
        #endif

        Task { @MainActor in
            do {
                // Publisher integration step 2: after the host app has completed its own
                // privacy/consent flow and permits ad requests, call start() exactly once from the
                // application root. Startup runs asynchronously, so it must not block navigation;
                // screens may open while settings and ads are still being prepared.
                try await adWall.start()
                scenarioList.completeAdWallStart(with: nil)
            } catch {
                scenarioList.completeAdWallStart(with: error)
            }
        }
        return true
    }
}
