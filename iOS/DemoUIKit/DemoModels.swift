import UIKit

@objcMembers
public final class DemoArticle: NSObject {
    public let category: String
    public let title: String
    public let summary: String
    public let paragraphs: [String]
    public let symbolName: String
    public let color: UIColor

    public init(
        category: String,
        title: String,
        summary: String,
        paragraphs: [String],
        symbolName: String,
        color: UIColor
    ) {
        self.category = category
        self.title = title
        self.summary = summary
        self.paragraphs = paragraphs
        self.symbolName = symbolName
        self.color = color
    }
}

@objcMembers
public final class DemoContent: NSObject {
    public static let article = DemoArticle(
        category: "DEMO",
        title: "The article that opens before its locked tail",
        summary: "A five-part story demonstrating an open introduction followed by protected content through the end.",
        paragraphs: [
            "The first paragraph is open to everyone. It establishes the story and gives readers enough context to decide whether they want to continue.",
            "The second paragraph begins the protected chapter. This section is covered by MembranaAdWall until the reader chooses to watch the rewarded message.",
            "The third paragraph remains part of that protected chapter, preserving a meaningful block of premium content rather than hiding a single sentence.",
            "The fourth paragraph remains protected. Readers can continue scrolling, but access is granted only after completing the rewarded ad.",
            "The fifth and final paragraph is protected as well, demonstrating that the wall covers the article from the selected gate point to the end."
        ],
        symbolName: "doc.text.fill",
        color: .systemGray
    )

}

public extension UIViewController {
    /// Sets `navigationItem.prompt` on the next run loop turn instead of immediately.
    ///
    /// UIKit's navigation-bar prompt view can briefly report a zero-width
    /// `UIView-Encapsulated-Layout-Width` constraint if the prompt changes before the bar has
    /// finished its own layout pass — e.g. right at launch or mid-push-transition. That produces a
    /// benign but noisy "Unable to simultaneously satisfy constraints" log. Deferring one run loop
    /// turn lets the bar's own layout settle first.
    func demoSetPrompt(_ text: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationItem.prompt = text
        }
    }
}
