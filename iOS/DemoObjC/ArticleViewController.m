#import "ArticleViewController.h"
#import "DemoModels.h"
#import <MembranaAdWallSDK/MembranaAdWallSDK-Swift.h>

@interface ArticleViewController () <MBRAdWallDelegate>
@property (nonatomic, strong) DemoArticle *article;
@property (nonatomic, strong) MBRAdWall *adWall;
@property (nonatomic, assign) DemoArticleGateScope gateScope;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *protectedContent;
@property (nonatomic, strong, nullable) MBRAdWallAppearance *appearanceToRestore;
@end

@implementation ArticleViewController

- (instancetype)initWithArticle:(DemoArticle *)article
                          adWall:(MBRAdWall *)adWall
                       gateScope:(DemoArticleGateScope)gateScope {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _article = article;
        _adWall = adWall;
        _gateScope = gateScope;
        switch (gateScope) {
            case DemoArticleGateScopeWholePage: self.title = @"Whole page"; break;
            case DemoArticleGateScopePartialPage: self.title = @"Part of screen"; break;
            case DemoArticleGateScopeBrandedAppearance: self.title = @"Branded styling"; break;
        }
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    // Publisher integration step 3: add and constrain the content before asking the SDK to gate it.
    [self buildArticle];
    [self applyBrandAppearanceIfNeeded];
    __weak typeof(self) weakSelf = self;
    [self.adWall startWithCompletion:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        if (error) {
            self.navigationItem.prompt = @"Ads are currently unavailable";
            return;
        }
        UIView *gatedView = self.gateScope == DemoArticleGateScopePartialPage ? self.protectedContent : self.view;
        // Publisher integration step 4: gate the exact protected view, provide its presenting view
        // controller, and implement MBRAdWallDelegate for the terminal access decision.
        [self.adWall gateView:gatedView
                            in:self
                      delegate:self];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Restore the previous style so the other scenarios keep the SDK's own look. A wall already on
    // screen keeps the style it was shown with, so this is safe while a presentation is active.
    if (self.appearanceToRestore != nil) {
        self.adWall.appearance = self.appearanceToRestore;
        self.appearanceToRestore = nil;
    }
}

/// Remote settings always own the wall's text and logo; an appearance only restyles how that
/// content is drawn.
///
/// The per-presentation `appearance:` overload of `gate` is Swift-only, so Objective-C callers set
/// the instance-level property instead. It applies to every wall this instance presents from now
/// on, which is why this screen restores the previous value on the way out. Set it before
/// `startWithCompletion:` rather than inside the completion, so navigating away early cannot leave
/// the override in place.
- (void)applyBrandAppearanceIfNeeded {
    if (self.gateScope != DemoArticleGateScopeBrandedAppearance) { return; }
    self.appearanceToRestore = self.adWall.appearance;
    // Objective-C has no copy-style initializer, so every value is listed. Everything except the
    // call to action repeats the SDK's own defaults.
    self.adWall.appearance = [[MBRAdWallAppearance alloc]
        initWithBackdropColor:UIColor.systemBackgroundColor
          cardBackgroundColor:UIColor.secondarySystemBackgroundColor
                   titleColor:UIColor.labelColor
             descriptionColor:UIColor.secondaryLabelColor
        buttonBackgroundColor:UIColor.systemPinkColor
        buttonForegroundColor:UIColor.whiteColor
             closeButtonColor:UIColor.labelColor
                    titleFont:[UIFont fontWithName:@"AvenirNext-Bold" size:22]
              descriptionFont:[UIFont fontWithName:@"AvenirNext-Regular" size:17]
                   buttonFont:[UIFont fontWithName:@"AvenirNext-DemiBold" size:17]];
}

- (void)buildArticle {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 18;
    stack.layoutMargins = UIEdgeInsetsMake(20, 24, 48, 24);
    stack.layoutMarginsRelativeArrangement = YES;
    [self.scrollView addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor]
    ]];

    UILabel *category = [self label:self.article.category style:UIFontTextStyleCaption1 color:self.article.color];
    UILabel *title = [self label:self.article.title style:UIFontTextStyleTitle1 color:UIColor.labelColor];
    UILabel *summary = [self label:self.article.summary style:UIFontTextStyleTitle3 color:UIColor.secondaryLabelColor];
    [stack addArrangedSubview:category];
    [stack addArrangedSubview:title];
    [stack addArrangedSubview:summary];

    UIView *hero = [[UIView alloc] init];
    hero.backgroundColor = self.article.color;
    hero.layer.cornerRadius = 12;
    hero.clipsToBounds = YES;
    UIImageView *symbol = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:self.article.symbolName]];
    symbol.translatesAutoresizingMaskIntoConstraints = NO;
    symbol.tintColor = UIColor.whiteColor;
    symbol.contentMode = UIViewContentModeScaleAspectFit;
    [hero addSubview:symbol];
    [NSLayoutConstraint activateConstraints:@[
        [hero.heightAnchor constraintEqualToConstant:180],
        [symbol.centerXAnchor constraintEqualToAnchor:hero.centerXAnchor],
        [symbol.centerYAnchor constraintEqualToAnchor:hero.centerYAnchor],
        [symbol.widthAnchor constraintEqualToConstant:72],
        [symbol.heightAnchor constraintEqualToConstant:72]
    ]];
    if (self.article.paragraphs.count > 0) {
        [stack addArrangedSubview:[self label:self.article.paragraphs.firstObject
                                        style:UIFontTextStyleBody
                                        color:UIColor.labelColor]];
    }

    self.protectedContent = [[UIView alloc] init];
    UIStackView *protectedStack = [[UIStackView alloc] init];
    protectedStack.translatesAutoresizingMaskIntoConstraints = NO;
    protectedStack.axis = UILayoutConstraintAxisVertical;
    protectedStack.spacing = 18;
    [protectedStack addArrangedSubview:hero];
    for (NSUInteger index = 1; index < self.article.paragraphs.count; index++) {
        [protectedStack addArrangedSubview:[self label:self.article.paragraphs[index] style:UIFontTextStyleBody color:UIColor.labelColor]];
    }
    [self.protectedContent addSubview:protectedStack];
    [NSLayoutConstraint activateConstraints:@[
        [protectedStack.leadingAnchor constraintEqualToAnchor:self.protectedContent.leadingAnchor],
        [protectedStack.trailingAnchor constraintEqualToAnchor:self.protectedContent.trailingAnchor],
        [protectedStack.topAnchor constraintEqualToAnchor:self.protectedContent.topAnchor],
        [protectedStack.bottomAnchor constraintEqualToAnchor:self.protectedContent.bottomAnchor]
    ]];
    [stack addArrangedSubview:self.protectedContent];
}

- (UILabel *)label:(NSString *)text style:(UIFontTextStyle)style color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:style];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = color;
    label.numberOfLines = 0;
    return label;
}

- (void)adWallDidUnlockContent:(MBRAdWall *)adWall {
    // Publisher integration step 5: this callback is the successful access grant.
    // Deferred one run loop turn: see the comment in ScenarioListViewController.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.prompt = @"Unlocked by a rewarded ad";
    });
}

- (void)adWallDidRejectContent:(MBRAdWall *)adWall {
    // Keep content protected or install the publisher's fallback when access is not earned.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.prompt = @"Publisher handled rejection";
    });
}

- (void)adWall:(MBRAdWall *)adWall contentUnavailableWithReason:(MBRUnavailableReason)reason {
    // Capping and no-fill are expected production states. Keep premium content protected and
    // provide the publisher's own login, subscription, or retry path.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.prompt = @"No wall available; publisher fallback applied";
    });
}

- (void)adWall:(MBRAdWall *)adWall didFailWithError:(NSError *)error {
    // Send technical failures to publisher diagnostics, then keep content protected or replace it
    // with an app-owned fallback. Never unlock from this callback.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.prompt = @"Ad error; publisher fallback applied";
    });
}

@end
