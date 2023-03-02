import CounterDomain
import StateTreeReporter
import UIKit

// MARK: - CountersListViewController

public final class CountersListViewController: UIViewController {

  // MARK: Lifecycle

  public init(
    model: Reported<CountersList>
  ) {
    _model = model
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Private

  /// The `@Updating` property wrapper provides callback allowing
  /// us to update values in UIKit based on changes to the model's
  /// underlying data.
  @Reported private var model: CountersList
  private lazy var mainView = UITableView()
}

extension CountersListViewController {

  // MARK: Public

  public override func loadView() {
    view = mainView
    mainView.delegate = self
    mainView.dataSource = self
    IconCell.register(in: mainView)
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    $model.onChange(subscriber: self) {
      self.mainView.reloadData()
    }
    mainView.reloadData()
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    $model.unregister(subscriber: self)
  }

  // MARK: Internal

  func toggleEditing() -> Bool {
    mainView.setEditing(!mainView.isEditing, animated: true)
    return mainView.isEditing
  }

}

// MARK: UITableViewDelegate

extension CountersListViewController: UITableViewDelegate {
  public func tableView(
    _ tableView: UITableView,
    didSelectRowAt indexPath: IndexPath
  ) {
    let counter = $model.$counters[indexPath.row]
    navigationController?.pushViewController(CounterViewController(model: counter), animated: true)
    tableView.deselectRow(at: indexPath, animated: true)
  }

  public func tableView(
    _: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  )
    -> UISwipeActionsConfiguration?
  {
    guard let counter = model.counters?[indexPath.row]
    else {
      return nil
    }
    return .init(
      actions: [
        UIContextualAction(
          style: .destructive,
          title: "Delete",
          handler: { [model] _, _, _ in
            model.delete(counter: counter.id)
          }
        ),
      ]
    )
  }

}

// MARK: UITableViewDataSource

extension CountersListViewController: UITableViewDataSource {

  public func tableView(
    _: UITableView,
    numberOfRowsInSection _: Int
  )
    -> Int
  {
    model.counters?.count ?? 0
  }

  public func numberOfSections(
    in _: UITableView
  )
    -> Int
  {
    1
  }

  public func tableView(
    _ tableView: UITableView,
    cellForRowAt _: IndexPath
  )
    -> UITableViewCell
  {
    IconCell.dequeue(from: tableView) ?? UITableViewCell()
  }

  public func tableView(
    _: UITableView,
    willDisplay cell: UITableViewCell,
    forRowAt indexPath: IndexPath
  ) {
    if
      let cell = cell as? IconCell,
      let counter = model.counters?[indexPath.row]
    {
      cell.icon = counter.emoji.image(size: 30)
      cell.count = counter.count
    }
  }

}
