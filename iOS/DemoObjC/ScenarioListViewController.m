#import "ScenarioListViewController.h"
#import "ArticleViewController.h"
#import "DemoModels.h"
#import <MembranaAdWallSDK/MembranaAdWallSDK-Swift.h>

@interface ScenarioListViewController ()
@property (nonatomic, strong) MBRAdWall *adWall;
@property (nonatomic, strong) UIActivityIndicatorView *initializationIndicator;
@end

@implementation ScenarioListViewController

- (instancetype)initWithAdWall:(MBRAdWall *)adWall {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _adWall = adWall;
        self.title = @"AdWall Scenarios";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"Article"];
    self.tableView.rowHeight = 118;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.initializationIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.initializationIndicator.accessibilityLabel = @"Preparing ads";
    [self.initializationIndicator startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.initializationIndicator];
}

- (void)completeAdWallStartWithError:(NSError *)error {
    [self.initializationIndicator stopAnimating];
    self.navigationItem.rightBarButtonItem = nil;
    // Deferred one run loop turn: setting the prompt before the nav bar's own layout pass has
    // settled (e.g. right at launch) can briefly report a benign but noisy zero-width constraint
    // conflict on its internal prompt view.
    NSString *prompt = error ? @"Ads are currently unavailable" : nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.prompt = prompt;
    });
}

+ (DemoArticleGateScope)scopeForRow:(NSInteger)row {
    switch (row) {
        case 0: return DemoArticleGateScopeWholePage;
        case 1: return DemoArticleGateScopePartialPage;
        default: return DemoArticleGateScopeBrandedAppearance;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Article" forIndexPath:indexPath];
    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    switch ([ScenarioListViewController scopeForRow:indexPath.row]) {
        case DemoArticleGateScopeWholePage:
            content.text = @"Whole page";
            content.secondaryText = @"Protect the complete article from the first frame";
            content.image = [UIImage systemImageNamed:@"rectangle.fill"];
            break;
        case DemoArticleGateScopePartialPage:
            content.text = @"Part of screen";
            content.secondaryText = @"Keep the introduction visible and gate the remaining article";
            content.image = [UIImage systemImageNamed:@"rectangle.split.2x1"];
            break;
        case DemoArticleGateScopeBrandedAppearance:
            content.text = @"Branded styling";
            content.secondaryText = @"Same whole-page coverage, restyled with publisher colors and fonts";
            content.image = [UIImage systemImageNamed:@"paintpalette"];
            break;
    }
    content.imageProperties.tintColor = UIColor.systemPinkColor;
    content.textProperties.numberOfLines = 2;
    content.secondaryTextProperties.numberOfLines = 2;
    cell.contentConfiguration = content;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DemoArticleGateScope scope = [ScenarioListViewController scopeForRow:indexPath.row];
    UIViewController *controller = [[ArticleViewController alloc] initWithArticle:DemoContent.article
                                                                           adWall:self.adWall
                                                                        gateScope:scope];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
