import CounterDomain
import StateTreeUIKit
import UIKit

// MARK: - CounterViewController

final class CounterViewController: UIViewController {

  init(model: Counter) {
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
  @Updating var model: Counter

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

    // When the view is about to become visible
    // subscribe to changes to the model and bind
    // them to the UI.
    $model.onChange(owner: self) { this, model in
      this.mainView.label
        .text = """
        \(model.emoji.string)

        \(model.count)
        """
    }

    // When becoming visible, if the `controls` submodel
    // of our model is available, create the view controller
    // that can host it and embed that view controller
    // within this one.
    if let controls = model.controls {
      let controlsVC = ControlsViewController(model: controls)
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
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    // Remove our subscription to model updates
    // when our view is no longer visible.
    $model.unregister(owner: self)

    // Tear down the child view embedding that
    // we did as part of `viewWillAppear()`.
    if let controlsChildVC {
      controlsChildVC.willMove(toParent: nil)
      controlsChildVC.removeFromParent()
      controlsChildVC.view.removeFromSuperview()
    }
    controlsChildVC = nil
  }

  private var controlsChildVC: ControlsViewController?
  private lazy var mainView = CounterView()
}

// MARK: - CounterView

final class CounterView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(label)
    addSubview(infoView)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

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
