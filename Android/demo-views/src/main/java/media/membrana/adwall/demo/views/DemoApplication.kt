package media.membrana.adwall.demo.views

import android.app.Application
import media.membrana.adwall.AdWall

/**
 * The App ID Membrana supplies for your application. This example uses Membrana's standard example
 * configuration, which shows the wall with a close control.
 *
 * A second example configuration is available if you want to see a rewarded-only wall, where the
 * only way past the gate is to watch the rewarded ad. To try it, comment the line below and
 * uncomment the alternative.
 */
private const val DEMO_APP_ID = "membrana-media-demo"
// private const val DEMO_APP_ID = "membrana-media-demo-rewarded-only"

/** The sample owns its configuration and uses only the SDK's public API. */
class DemoApplication : Application() {
    val adWall: AdWall by lazy {
        // Publisher integration step 1: create one application-scoped SDK instance with the App ID
        // Membrana supplies for your application, retain it for the lifetime of the app, and pass
        // that same instance to every screen you gate. Do not create a second instance per screen.
        AdWall(this, DEMO_APP_ID).apply {
            // Optional test integration. While integrating, you can run the SDK against Google's
            // dedicated test ad units and a capping ledger isolated from production, so no real
            // inventory is requested and your production capping history is untouched. Uncomment
            // the call below to enable it; it must run before start().
            //
            // Remove or disable this call before shipping to production: it changes ad
            // configuration and capping behavior, and suppresses analytics delivery by default. The
            // SDK does not prevent enabling it in a distributed app.
            //
            // enableIntegrationTesting()
        }
    }
}
