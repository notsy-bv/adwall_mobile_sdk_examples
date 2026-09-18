import MembranaAdWallSDK
import UIKit

final class ScenarioListViewController: UITableViewController {
    private enum Scenario: CaseIterable {
        case wholePage
        case partialPage
        case brandedAppearance

        var title: String {
            switch self {
            case .wholePage: return "Whole page"
            case .partialPage: return "Part of screen"
            case .brandedAppearance: return "Branded styling"
            }
        }

        var detail: String {
            switch self {
            case .wholePage: return "Protect the complete article from the first frame"
            case .partialPage: return "Keep the introduction visible and gate the remaining article"
            case .brandedAppearance: return "Same whole-page coverage, restyled with publisher colors and fonts"
            }
        }

        var symbol: String {
            switch self {
            case .wholePage: return "rectangle.fill"
            case .partialPage: return "rectangle.split.2x1"
            case .brandedAppearance: return "paintpalette"
            }
        }

        var gateScope: ArticleGateScope {
            switch self {
            case .wholePage: return .wholePage
            case .partialPage: return .partialPage
            case .brandedAppearance: return .brandedAppearance
            }
        }
    }

    private let adWall: MembranaAdWall
    private let initializationIndicator = UIActivityIndicatorView(style: .medium)

    init(adWall: MembranaAdWall) {
        self.adWall = adWall
        super.init(style: .insetGrouped)
        title = "AdWall Scenarios"
        navigationItem.largeTitleDisplayMode = .always
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Scenario")
        tableView.rowHeight = 82
        tableView.accessibilityIdentifier = "scenario.list"
        initializationIndicator.accessibilityLabel = "Preparing test ads"
        initializationIndicator.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: initializationIndicator)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Scenario.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let scenario = Scenario.allCases[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Scenario", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = scenario.title
        content.secondaryText = scenario.detail
        content.image = UIImage(systemName: scenario.symbol)
        content.imageProperties.tintColor = .systemPink
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let scenario = Scenario.allCases[indexPath.row]
        let controller = ArticleViewController(
            article: DemoContent.article,
            adWall: adWall,
            gateScope: scenario.gateScope
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    func completeAdWallStart(with error: Error?) {
        initializationIndicator.stopAnimating()
        navigationItem.rightBarButtonItem = nil
        demoSetPrompt(error == nil ? "Google test ads ready" : "Ads are currently unavailable")
    }
}
