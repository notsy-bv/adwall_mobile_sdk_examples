#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "ScenarioListViewController.h"
#import <MembranaAdWallSDK/MembranaAdWallSDK-Swift.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) {
        return;
    }
    MBRAdWall *adWall = ((AppDelegate *)UIApplication.sharedApplication.delegate).adWall;

    ScenarioListViewController *scenarios = [[ScenarioListViewController alloc] initWithAdWall:adWall];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:scenarios];

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    // Publisher integration step 2: after the host app has completed its own privacy/consent flow
    // and permits ad requests, start the SDK once from the scene that builds the application root.
    // Startup runs asynchronously, so it must not block navigation; screens may open while it is
    // still running. Startup is process-wide, so if the system reconnects this scene later,
    // starting again after a successful start completes immediately.
    [adWall startWithCompletion:^(NSError *error) {
        [scenarios completeAdWallStartWithError:error];
    }];
}

@end
