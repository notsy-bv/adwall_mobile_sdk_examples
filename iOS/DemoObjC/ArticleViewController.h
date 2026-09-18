#import <UIKit/UIKit.h>
#import "DemoModels.h"
@class MBRAdWall;

typedef NS_ENUM(NSUInteger, DemoArticleGateScope) {
    DemoArticleGateScopeWholePage,
    DemoArticleGateScopePartialPage,
    /// Same whole-page coverage as DemoArticleGateScopeWholePage; only the wall's styling differs.
    DemoArticleGateScopeBrandedAppearance
};

@interface ArticleViewController : UIViewController
- (instancetype)initWithArticle:(DemoArticle *)article
                         adWall:(MBRAdWall *)adWall
                       gateScope:(DemoArticleGateScope)gateScope;
@end
