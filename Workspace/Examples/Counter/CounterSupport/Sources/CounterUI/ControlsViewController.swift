import CounterDomain
import StateTreeReporter
import UIKit

// MARK: - ControlsViewController

final class ControlsViewController: UIViewController {

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
    view = mainView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Bind the `addButton` `UIButton` to our model's
    // `increment()` method.
    mainView.addButton
      .addAction(
        UIAction { [model] _ in
          model.increment()
        },
        for: .touchUpInside
      )

    // Bind the `subtractButton` `UIButton` to our
    // model's `decrement` method.
    mainView.subtractButton
      .addAction(
        UIAction { [model] _ in
          model.decrement()
        },
        for: .touchUpInside
      )
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    $model.onChange(subscriber: self) { [self] in
      mainView.addButton.isEnabled = !model.incrementDisabled
      mainView.subtractButton.isEnabled = !model.decrementDisabled
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    $model.unregister(subscriber: self)
  }

  // MARK: Private

  private lazy var mainView = ControlsView()

}

// MARK: - ControlsView

final class ControlsView: UIView {

  // MARK: Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(addButton)
    addSubview(subtractButton)
    setup()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let addButton: UIButton = {
    let button = UIButton()
    button.configuration = .bordered()
    button.setTitle("➕", for: .normal)
    button.setTitle("❌", for: .disabled)
    return button
  }()

  let subtractButton: UIButton = {
    let button = UIButton()
    button.configuration = .bordered()
    button.setTitle("➖", for: .normal)
    button.setTitle("❌", for: .disabled)
    return button
  }()

  func setup() {
    addButton.translatesAutoresizingMaskIntoConstraints = false
    subtractButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      addButton.topAnchor
        .constraint(equalTo: topAnchor),
      addButton.bottomAnchor
        .constraint(equalTo: bottomAnchor),
      addButton.leadingAnchor
        .constraint(equalTo: leadingAnchor),
      addButton.widthAnchor
        .constraint(equalTo: subtractButton.widthAnchor),
      subtractButton.leadingAnchor
        .constraint(equalTo: addButton.trailingAnchor, constant: 8),
      subtractButton.topAnchor
        .constraint(equalTo: topAnchor),
      subtractButton.bottomAnchor
        .constraint(equalTo: bottomAnchor),
      subtractButton.trailingAnchor
        .constraint(equalTo: trailingAnchor),
    ])
  }
}
