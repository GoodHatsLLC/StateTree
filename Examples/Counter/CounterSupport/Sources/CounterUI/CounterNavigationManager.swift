import CounterDomain
import StateTreeUIKit
import UIKit

// MARK: - CounterNavigationManager

/// A manager for the UIKit navigation controller.
///
/// This example code is written with the philosophy
/// that since view controllers embedded in a navigation
/// controller don't directly own it, they should not directly
/// act on it.
///
/// As a result both this navigation manager and its root
/// view controller interact with parts of the `CountersList`
/// model. That's fine. The view layer and the domain layer
/// don't have to have a 1:1 mapping.
///
/// This philosophy doesn't directly relate to StateTree use,
/// but writing code with very clear layers of ownership is
/// probably a good idea when trying to bridge a declarative
/// system like StateTree into an imperative model like UIKit.
///
/// Use a declarative view layer where possible. Let the the
/// platform own the state handling complexity.
@MainActor
public final class CounterNavigationManager {

  public init(model: CountersList) {
    self.model = model
    let rootVC = CountersListViewController(model: model)
    let navVC = UINavigationController(rootViewController: rootVC)
    self.rootVC = rootVC
    self.navVC = navVC
    rootVC.navigationItem.rightBarButtonItem = .init(
      barButtonSystemItem: .add,
      target: self,
      action: #selector(didTapAdd)
    )
    rootVC.navigationItem.leftBarButtonItem = .init(
      barButtonSystemItem: .edit,
      target: self,
      action: #selector(didTapEdit)
    )
  }

  /// The navigation controller this class manages.
  public let navVC: UINavigationController

  /// The `CounterNavigationManager` must be explicitly started
  /// since it doesn't have a view lifecycle we can bind its model subscription to.
  public func start() {
    $model
      .onChange(owner: self) { this, model in

        if let counter = model.selected {
          // If the model has a selected counter sub-model we
          // create a view controller for it.
          if this.selectedCounterVC == nil {
            let counterVC = CounterViewController(model: counter)

            // Since we're controlling the navigation stack
            // we override the back action to update the
            // model based on the user's intent to deselect the
            // selected counter.
            counterVC.navigationItem.backAction = UIAction { _ in
              model.select(counter: nil)
            }
            // setting this property manipulates the back stack
            // to add the view controller
            this.selectedCounterVC = counterVC
          }
        } else {
          // setting this property manipulates the back stack
          // to remove the view controller
          this.selectedCounterVC = nil
        }
      }
  }

  /// The `CounterNavigationManager` must be explicitly stopped
  /// since it doesn't have a view lifecycle we can bind its model subscription to.
  public func stop() {
    $model.unregister(owner: self)
  }

  /// The behavior bound to the '+' navigation item button
  @objc
  func didTapAdd() {
    model.addCounter()
  }

  /// The behavior bound to the 'Edit' navigation item button
  @objc
  func didTapEdit() {
    let isEditing = rootVC.toggleEditing()
    rootVC.navigationItem.leftBarButtonItem?.isSelected = isEditing
  }

  /// The model this class controls and reacts to.
  ///
  /// The `@Updating` property wrapper provides callback allowing
  /// us to update values in UIKit based on changes to the model's
  /// underlying data.
  @Updating private var model: CountersList
  private let rootVC: CountersListViewController

  private var selectedCounterVC: UIViewController? {
    didSet { updateNavigationStack() }
  }

  private func updateNavigationStack() {
    navVC.setViewControllers(
      [
        rootVC,
        selectedCounterVC,
      ].compactMap { $0 },
      animated: true
    )
  }
}
