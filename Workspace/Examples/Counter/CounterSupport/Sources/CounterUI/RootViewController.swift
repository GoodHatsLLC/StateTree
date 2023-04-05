import CounterDomain
import StateTreeCallbacks
import UIKit

public class RootViewController: UIViewController {

  // MARK: Lifecycle

  public init(model: Reported<CountersList>) {
    _counters = model
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public

  public override func viewDidLoad() {
    super.viewDidLoad()

    let countersVC = CountersListViewController(model: $counters)
    let navVc = UINavigationController(rootViewController: countersVC)
    countersVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "+",
      style: .plain,
      target: self,
      action: #selector(addCounter)
    )
    view.addSubview(navVc.view)
    view
      .translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      navVc.view.leadingAnchor
        .constraint(equalTo: view.leadingAnchor),
      navVc.view.trailingAnchor
        .constraint(equalTo: view.trailingAnchor),
      navVc.view.topAnchor
        .constraint(equalTo: view.topAnchor),
      navVc.view.bottomAnchor
        .constraint(equalTo: view.bottomAnchor),
    ])
    addChild(navVc)
    navVc.didMove(toParent: self)
  }

  // MARK: Internal

  @Reported var counters: CountersList

  @objc
  func addCounter() {
    counters.addCounter()
  }
}
