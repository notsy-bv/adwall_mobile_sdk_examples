#import "AppDelegate.h"
#import "DemoModels.h"
#import "ScenarioListViewController.h"
#import <MembranaAdWallSDK/MembranaAdWallSDK-Swift.h>

/// The App ID Membrana supplies for your application. This example uses Membrana's standard
/// example configuration, which shows the wall with a close control.
///
/// A second example configuration is available if you want to see a rewarded-only wall, where the
/// only way past the gate is to watch the rewarded ad. To try it, comment the line below and
/// uncomment the alternative.
static NSString *DemoAdWallAppID(void) {
    return @"membrana-media-example";
    // return @"membrana-media-example-rewarded-only";
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Publisher integration step 1: create one application-scoped SDK instance with the App ID
    // Membrana supplies for your application, retain it for the lifetime of the app, and pass that
    // same instance to each gated view controller. Do not create a second instance per screen.
    MBRAdWall *adWall = [[MBRAdWall alloc] initWithAppId:DemoAdWallAppID()];

    // Optional test integration. While integrating, you can run the SDK against Google's dedicated
    // test ad units and a capping ledger isolated from production, so no real inventory is
    // requested and your production capping history is untouched. Uncomment the block below to
    // enable it.
    //
    // Remove or disable this call before shipping to production: it changes ad configuration and
    // capping behavior, and suppresses analytics delivery by default. The SDK does not prevent
    // enabling it in a distributed app.
    //
    // MBRAdWallIntegrationTestOptions *testOptions =
    //     MBRAdWallIntegrationTestOptions.googleTestAdsWithCappingDisabled;
    // NSError *testModeError = nil;
    // [adWall enableIntegrationTestingWithOptions:testOptions error:&testModeError];
    // NSAssert(testModeError == nil,
    //          @"Unable to enable AdWall integration testing: %@", testModeError);

    ScenarioListViewController *scenarios = [[ScenarioListViewController alloc] initWithAdWall:adWall];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:scenarios];

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    // Publisher integration step 2: after the host app has completed its own privacy/consent flow
    // and permits ad requests, start the SDK exactly once from the application root. Startup runs
    // asynchronously, so it must not block navigation; screens may open while it is still running.
    [adWall startWithCompletion:^(NSError *error) {
        [scenarios completeAdWallStartWithError:error];
    }];
    return YES;
}

@end
