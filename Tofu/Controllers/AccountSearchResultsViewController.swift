import UIKit

private let accountCellIdentifier = "AccountCell"

class AccountSearchResultsViewController: UITableViewController, AccountUpdateDelegate, UIEditMenuInteractionDelegate {
    @IBOutlet var emptyView: UIView!

    private lazy var editMenuInteraction: UIEditMenuInteraction = {
        return UIEditMenuInteraction(delegate: self)
    }()

    var accounts: [Account]! {
        didSet {
            tableView.reloadData()
            tableView.backgroundView = accounts.count == 0 ? emptyView : nil
            tableView.separatorStyle = accounts.count == 0 ? .none : .singleLine
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let updater = AccountsTableViewUpdater(tableView: tableView)
        updater.startUpdating()
        tableView.addInteraction(editMenuInteraction)
    }

    @objc func deselectSelectedTableViewRow() {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: UIEditMenuInteractionDelegate

    private var editMenuVisible: Bool = false

    func editMenuInteraction(_ interaction: UIEditMenuInteraction, willPresentMenuFor configuration: UIEditMenuConfiguration,
                             animator: any UIEditMenuInteractionAnimating) {
        editMenuVisible = true
    }

    func editMenuInteraction(_ interaction: UIEditMenuInteraction, willDismissMenuFor configuration: UIEditMenuConfiguration,
                             animator: any UIEditMenuInteractionAnimating) {
        editMenuVisible = false
        deselectSelectedTableViewRow()
    }

    func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration,
                             suggestedActions: [UIMenuElement]) -> UIMenu? {
        let copyItem = UIAction(title: Localizable.copyMenuItemTitle, image: nil) { [weak self] action in
            guard let self, let tableView = self.tableView else { return }
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.cellForRow(at: indexPath)?.copy(self)
            }
        }

        return UIMenu(title: Localizable.copyMenuItemTitle, image: nil, identifier: nil, options: .displayInline,
                      children: [copyItem])
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            // If you tap the same cell twice, this condition prevents the menu from being
            // hidden and then instantly shown again causing an unpleasant flash.
            //
            // Since the cell could already be the first responder (from previously showing
            // its menu and then scrolling the table view) and the menu could already be
            // visible for another cell, we make sure to check both values.
            if !(cell.isFirstResponder && editMenuVisible) {
                cell.becomeFirstResponder()
                let config = UIEditMenuConfiguration(identifier: nil, sourcePoint: CGPoint(x: cell.center.x, y: cell.frame.maxY))
                editMenuInteraction.presentEditMenu(with: config)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: accountCellIdentifier,
                                                 for: indexPath) as! AccountCell
        cell.account = accounts[indexPath.row]
        cell.delegate = self
        return cell
    }

    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView,
                            shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector,
                            forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }
    
    override func tableView(_ tableView: UITableView, performAction action: Selector,
                            forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_:)) {
            let cell = tableView.cellForRow(at: indexPath) as! AccountCell
            cell.copy(self)
        }
    }
    
    // MARK: AccountUpdateDelegate
    
    func updateAccount(_ account: Account) {
        (presentingViewController as! AccountUpdateDelegate).updateAccount(account)
        let row = accounts.firstIndex { $0 === account }!
        let indexPath = IndexPath(row: row, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) as? AccountCell else { return }
        cell.updateWithDate(Date())
    }
}
