import CounterDomain
import StateTreeUIKit
import UIKit

// MARK: - CountersListViewController

final class CountersListViewController: UIViewController {

  init(
    model: CountersList
  ) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// The `@Updating` property wrapper provides callback allowing
  /// us to update values in UIKit based on changes to the model's
  /// underlying data.
  @Updating private var model: CountersList
  private lazy var mainView = UITableView()
}

extension CountersListViewController {

  override func loadView() {
    view = mainView
    mainView.delegate = self
    mainView.dataSource = self
    IconCell.register(in: mainView)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    $model.onChange(owner: self) { owner, _ in
      owner.mainView.reloadData()
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    $model.unregister(owner: self)
  }

  func toggleEditing() -> Bool {
    mainView.setEditing(!mainView.isEditing, animated: true)
    return mainView.isEditing
  }

}

// MARK: UITableViewDelegate

extension CountersListViewController: UITableViewDelegate {
  func tableView(
    _ tableView: UITableView,
    didSelectRowAt indexPath: IndexPath
  ) {
    let counter = model.counters[indexPath.row]
    model.select(counter: counter)
    tableView.deselectRow(at: indexPath, animated: true)
  }

  func tableView(
    _: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  )
    -> UISwipeActionsConfiguration?
  {
    let counter = model.counters[indexPath.row]
    return .init(
      actions: [
        UIContextualAction(
          style: .destructive,
          title: "Delete",
          handler: { [model] _, _, _ in
            model.removeCounter(counter)
          }
        )
      ]
    )
  }

}

// MARK: UITableViewDataSource

extension CountersListViewController: UITableViewDataSource {

  func tableView(
    _: UITableView,
    numberOfRowsInSection _: Int
  )
    -> Int
  {
    model.counters.count
  }

  func numberOfSections(
    in _: UITableView
  )
    -> Int
  {
    1
  }

  func tableView(
    _ tableView: UITableView,
    cellForRowAt _: IndexPath
  )
    -> UITableViewCell
  {
    IconCell.dequeue(from: tableView) ?? UITableViewCell()
  }

  func tableView(
    _: UITableView,
    willDisplay cell: UITableViewCell,
    forRowAt indexPath: IndexPath
  ) {
    if let cell = cell as? IconCell {
      let counter = model.counters[indexPath.row]
      cell.icon = counter.emoji.image(size: 30)
      cell.count = counter.count
    }
  }

}
