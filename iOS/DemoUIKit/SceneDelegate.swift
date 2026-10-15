import MembranaAdWallSDK
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene,
              let adWall = (UIApplication.shared.delegate as? AppDelegate)?.adWall else { return }

        let scenarioList = ScenarioListViewController(adWall: adWall)
        let scenarios = UINavigationController(rootViewController: scenarioList)
        scenarios.tabBarItem = UITabBarItem(title: "Today", image: UIImage(systemName: "newspaper"), tag: 0)

        let window = UIWindow(windowScene: windowScene)
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
                // privacy/consent flow and permits ad requests, call start() once from the scene
                // that builds the application root. Startup runs asynchronously, so it must not
                // block navigation; screens may open while settings and ads are still being
                // prepared. Startup is process-wide, so if the system reconnects this scene later,
                // calling start() again after it has succeeded returns immediately.
                try await adWall.start()
                scenarioList.completeAdWallStart(with: nil)
            } catch {
                scenarioList.completeAdWallStart(with: error)
            }
        }
    }
}
