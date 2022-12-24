import CounterDomain
import CounterUI
import StateTree
import UIKit

/// We use the SceneDelegate as our entry point into our StateTree
/// defined domain logic.
/// (The rest of the Counter example code is in the `CounterSupport` package.)
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  /// The model representing our StateTree
  ///
  /// This Tree manages all of our models
  let tree = Tree(rootModelState: CountersList.State()) { store in
    CountersList(store: store)
  }

  /// The manager responsible for the top level navigation controller
  var navigationManager: CounterNavigationManager?

  func scene(
    _ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions
  ) {
    guard let scene = (scene as? UIWindowScene) else {
      return
    }
    let mainWindow = UIWindow(windowScene: scene)
    window = mainWindow

    // StateTree's root `Tree` needs to be started.
    // We do so and bind the resulting `AnyDisposable`
    // to the app's lifetime.
    // (An `AnyDisposable` behaves like a Combine
    // `AnyCancellable` or an RxSwift `Disposable`)
    try? tree
      .start()
      .stageIndefinitely()

    // Instantiate our root-level view layer manager
    // with our root level model.
    let navigationManager = CounterNavigationManager(
      model: tree.rootModel
    )
    self.navigationManager = navigationManager

    // (Implementation detail.)
    // Since the navigation manager doesn't have a
    // view lifecycle to bind to it exposes `start()`
    // and `stop()` methods.
    // We wrap them up and bind their lifetime to the
    // app, just like the `tree`.
    navigationManager.start()
    AnyDisposable {
      navigationManager.stop()
    }
    .stageIndefinitely()

    // We've finished setting up.
    // Kick off the view hierarchy.
    mainWindow.rootViewController = navigationManager.navVC
    window?.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_: UIScene) {}

  func sceneDidBecomeActive(_: UIScene) {}

  func sceneWillResignActive(_: UIScene) {}

  func sceneWillEnterForeground(_: UIScene) {}

  func sceneDidEnterBackground(_: UIScene) {}

}
