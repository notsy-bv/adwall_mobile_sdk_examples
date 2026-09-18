#import <UIKit/UIKit.h>
@class MBRAdWall;

@interface ScenarioListViewController : UITableViewController
- (instancetype)initWithAdWall:(MBRAdWall *)adWall;
- (void)completeAdWallStartWithError:(NSError *)error;
@end
