#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DemoArticle : NSObject
@property (nonatomic, copy, readonly) NSString *category;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *summary;
@property (nonatomic, copy, readonly) NSArray<NSString *> *paragraphs;
@property (nonatomic, copy, readonly) NSString *symbolName;
@property (nonatomic, strong, readonly) UIColor *color;

- (instancetype)initWithCategory:(NSString *)category
                             title:(NSString *)title
                           summary:(NSString *)summary
                        paragraphs:(NSArray<NSString *> *)paragraphs
                        symbolName:(NSString *)symbolName
                             color:(UIColor *)color;
@end

@interface DemoContent : NSObject
+ (DemoArticle *)article;
@end

NS_ASSUME_NONNULL_END
