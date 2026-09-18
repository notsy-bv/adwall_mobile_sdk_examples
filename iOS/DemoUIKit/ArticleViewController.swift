import MembranaAdWallSDK
import UIKit

enum ArticleGateScope {
    case wholePage
    case partialPage
    /// Same whole-page coverage as `wholePage`; only the wall's styling differs.
    case brandedAppearance

    var navigationTitle: String {
        switch self {
        case .wholePage: return "Whole page"
        case .partialPage: return "Part of screen"
        case .brandedAppearance: return "Branded styling"
        }
    }

    var coversWholePage: Bool {
        self != .partialPage
    }

    /// Remote settings always own the wall's text and logo. An appearance only restyles how that
    /// content is drawn, so a publisher can match the card to its own design language. Returning
    /// `nil` leaves the SDK's own look in place.
    var appearance: MembranaAdWallAppearance? {
        guard self == .brandedAppearance else { return nil }
        return MembranaAdWallAppearance(
            buttonBackgroundColor: .systemPink,
            buttonForegroundColor: .white,
            titleFont: UIFont(name: "AvenirNext-Bold", size: 22),
            descriptionFont: UIFont(name: "AvenirNext-Regular", size: 17),
            buttonFont: UIFont(name: "AvenirNext-DemiBold", size: 17)
        )
    }
}

final class ArticleViewController: UIViewController, MembranaAdWallDelegate {
    private let article: DemoArticle
    private let adWall: MembranaAdWall
    private let gateScope: ArticleGateScope
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let protectedContent = UIView()
    private var gateTask: Task<Void, Never>?

    init(article: DemoArticle, adWall: MembranaAdWall, gateScope: ArticleGateScope = .partialPage) {
        self.article = article
        self.adWall = adWall
        self.gateScope = gateScope
        super.init(nibName: nil, bundle: nil)
        title = gateScope.navigationTitle
        navigationItem.largeTitleDisplayMode = .never
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        // Publisher integration step 3: add and fully constrain the content that must remain
        // protected before asking the SDK to gate it.
        configureArticle()
        gateWhenAdWallIsReady()
    }

    deinit {
        gateTask?.cancel()
    }

    private func gateWhenAdWallIsReady() {
        let adWall = adWall
        gateTask = Task { @MainActor [weak self] in
            do {
                try await adWall.start()
                guard !Task.isCancelled, let self else { return }
                // Publisher integration step 4: gate either the complete screen or the exact
                // protected subtree, and provide the presenting view controller plus delegate.
                adWall.gate(
                    gateScope.coversWholePage ? view : protectedContent,
                    in: self,
                    appearance: gateScope.appearance,
                    delegate: self
                )
            } catch {
                guard let self else { return }
                demoSetPrompt("Ads are currently unavailable")
            }
        }
    }

    private func configureArticle() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 18
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 24, bottom: 48, right: 24)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        let category = makeLabel(article.category, style: .caption1, color: article.color)
        let title = makeLabel(article.title, style: .title1)
        let summary = makeLabel(article.summary, style: .title3, color: .secondaryLabel)
        let hero = UIView()
        hero.backgroundColor = article.color
        hero.layer.cornerRadius = 12
        hero.clipsToBounds = true
        let symbol = UIImageView(image: UIImage(systemName: article.symbolName))
        symbol.translatesAutoresizingMaskIntoConstraints = false
        symbol.tintColor = .white
        symbol.contentMode = .scaleAspectFit
        hero.addSubview(symbol)
        NSLayoutConstraint.activate([
            hero.heightAnchor.constraint(equalToConstant: 180),
            symbol.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: hero.centerYAnchor),
            symbol.widthAnchor.constraint(equalToConstant: 72),
            symbol.heightAnchor.constraint(equalToConstant: 72)
        ])

        [category, title, summary].forEach(stack.addArrangedSubview)

        if let introduction = article.paragraphs.first {
            stack.addArrangedSubview(makeLabel(introduction, style: .body))
        }

        let protectedStack = UIStackView()
        protectedStack.translatesAutoresizingMaskIntoConstraints = false
        protectedStack.axis = .vertical
        protectedStack.spacing = 18
        protectedStack.addArrangedSubview(hero)
        article.paragraphs.dropFirst().forEach {
            protectedStack.addArrangedSubview(makeLabel($0, style: .body))
        }
        protectedContent.addSubview(protectedStack)
        NSLayoutConstraint.activate([
            protectedStack.leadingAnchor.constraint(equalTo: protectedContent.leadingAnchor),
            protectedStack.trailingAnchor.constraint(equalTo: protectedContent.trailingAnchor),
            protectedStack.topAnchor.constraint(equalTo: protectedContent.topAnchor),
            protectedStack.bottomAnchor.constraint(equalTo: protectedContent.bottomAnchor)
        ])
        stack.addArrangedSubview(protectedContent)
    }

    private func makeLabel(_ text: String, style: UIFont.TextStyle, color: UIColor = .label) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    func adWallDidUnlockContent(_ adWall: MembranaAdWall) {
        // Publisher integration step 5: treat this callback as the successful access grant.
        demoSetPrompt("Unlocked by a rewarded ad")
    }

    func adWallDidRejectContent(_ adWall: MembranaAdWall) {
        // Keep content protected or install the publisher's fallback when access is not earned.
        demoSetPrompt("Ad declined; publisher fallback applied")
    }

    func adWall(
        _ adWall: MembranaAdWall,
        contentUnavailableWithReason reason: MembranaAdWallUnavailableReason
    ) {
        // Routine states such as capping and no-fill belong here. Keep premium content protected
        // and offer the publisher's own login, subscription, or retry path.
        demoSetPrompt("No wall available; publisher fallback applied")
    }

    func adWall(_ adWall: MembranaAdWall, didFailWithError error: NSError) {
        // Report the technical error through the publisher's diagnostics, then keep content
        // protected or replace it with an app-owned fallback.
        demoSetPrompt("Ad error; publisher fallback applied")
    }
}
