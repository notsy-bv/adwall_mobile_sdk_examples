import MembranaAdWallSDK
import UIKit

/// The App ID Membrana supplies for your application. This example uses Membrana's standard
/// example configuration, which shows the wall with a close control.
///
/// A second example configuration is available if you want to see a rewarded-only wall, where the
/// only way past the gate is to watch the rewarded ad. To try it, comment the line below and
/// uncomment the alternative.
private let demoAppID = "membrana-media-demo"
// private let demoAppID = "membrana-media-demo-rewarded-only"

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
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
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
