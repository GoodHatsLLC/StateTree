import CounterDomain
import StateTreeCallbacks
import UIKit

// MARK: - CounterViewController

final class CounterViewController: UIViewController {

  // MARK: Lifecycle

  init(model: Reported<Counter>) {
    _model = model
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  @Reported var model: Counter

  override func loadView() {
    super.loadView()
    view = mainView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    mainView.setup()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    func update() {
      mainView.label.text =
        """
        \(model.emoji.string)

        \(model.count)
        """
    }

    // When the view is about to become visible
    // subscribe to changes to the model and bind
    // them to the UI.
    $model.onChange(subscriber: self) {
      update()
    }
    update()

    let controlsVC = ControlsViewController(model: $model)
    mainView.infoView
      .addSubview(controlsVC.view)
    controlsVC.view
      .translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      controlsVC.view.leadingAnchor
        .constraint(equalTo: mainView.infoView.leadingAnchor),
      controlsVC.view.trailingAnchor
        .constraint(equalTo: mainView.infoView.trailingAnchor),
      controlsVC.view.topAnchor
        .constraint(equalTo: mainView.infoView.topAnchor),
      controlsVC.view.bottomAnchor
        .constraint(equalTo: mainView.infoView.bottomAnchor),
    ])
    addChild(controlsVC)
    controlsVC.didMove(toParent: self)

    // If we made a child view controller track it so
    // that we can tear it down on `viewDidDisappear`.
    controlsChildVC = controlsVC
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // Remove our subscription to model updates
    // when our view is no longer visible.
    $model.unregister(subscriber: self)

    // Tear down the child view embedding that
    // we did as part of `viewWillAppear()`.
    if let controlsChildVC {
      controlsChildVC.willMove(toParent: nil)
      controlsChildVC.removeFromParent()
      controlsChildVC.view.removeFromSuperview()
    }
    controlsChildVC = nil
  }

  // MARK: Private

  private var controlsChildVC: ControlsViewController?
  private lazy var mainView = CounterView()
}

// MARK: - CounterView

final class CounterView: UIView {

  // MARK: Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(label)
    addSubview(infoView)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let label = UILabel()
  let infoView = UIView()

  func setup() {
    backgroundColor = .white
    label.translatesAutoresizingMaskIntoConstraints = false
    infoView.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.numberOfLines = 3
    label.font = UIFont.systemFont(ofSize: 40)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: centerXAnchor),
      label.bottomAnchor.constraint(equalTo: centerYAnchor),
      infoView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
      infoView.centerXAnchor.constraint(equalTo: centerXAnchor),
      infoView.widthAnchor.constraint(equalToConstant: 100),
    ])
  }

}
