import CounterDomain
import StateTreeUIKit
import UIKit

// MARK: - ControlsViewController

final class ControlsViewController: UIViewController {

  init(model: Controls) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// The `Controls` model this view controller represents.
  ///
  /// The `@Updating` property wrapper provides callback allowing
  /// us to update values in UIKit based on changes to the model's
  /// underlying data. (They're unused in this class.)
  @Updating var model: Controls

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

  private lazy var mainView = ControlsView()

}

// MARK: - ControlsView

final class ControlsView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(addButton)
    addSubview(subtractButton)
    setup()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let addButton: UIButton = {
    let button = UIButton()
    button.configuration = .bordered()
    button.setTitle("➕", for: .normal)
    return button
  }()

  let subtractButton: UIButton = {
    let button = UIButton()
    button.configuration = .bordered()
    button.setTitle("➖", for: .normal)
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
