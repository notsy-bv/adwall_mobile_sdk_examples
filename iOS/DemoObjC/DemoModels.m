#import "DemoModels.h"

@implementation DemoArticle

- (instancetype)initWithCategory:(NSString *)category
                             title:(NSString *)title
                           summary:(NSString *)summary
                        paragraphs:(NSArray<NSString *> *)paragraphs
                        symbolName:(NSString *)symbolName
                             color:(UIColor *)color {
    self = [super init];
    if (self) {
        _category = [category copy];
        _title = [title copy];
        _summary = [summary copy];
        _paragraphs = [paragraphs copy];
        _symbolName = [symbolName copy];
        _color = color;
    }
    return self;
}

@end

@implementation DemoContent

+ (DemoArticle *)article {
    static DemoArticle *article;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        article = [[DemoArticle alloc]
            initWithCategory:@"DEMO"
                    title:@"The article that opens before its locked tail"
                  summary:@"A five-part story demonstrating an open introduction followed by protected content through the end."
                    paragraphs:@[
                        @"The first paragraph is open to everyone. It establishes the story and gives readers enough context to decide whether they want to continue.",
                        @"The second paragraph begins the protected chapter. This section is covered by MembranaAdWall until the reader chooses to watch the rewarded message.",
                        @"The third paragraph remains part of that protected chapter, preserving a meaningful block of premium content rather than hiding a single sentence.",
                        @"The fourth paragraph remains protected. Readers can continue scrolling, but access is granted only after completing the rewarded ad.",
                        @"The fifth and final paragraph is protected as well, demonstrating that the wall covers the article from the selected gate point to the end."
                    ]
                    symbolName:@"doc.text.fill"
                         color:UIColor.systemGrayColor];
    });
    return article;
}

@end
