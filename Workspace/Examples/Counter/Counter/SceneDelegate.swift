import CounterDomain
import CounterUI
import StateTree
import StateTreeReporter
import UIKit

/// We use the SceneDelegate as our entry point into our StateTree
/// defined domain logic.
/// (The rest of the Counter example code is in the `CounterSupport` package.)
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  /// The model representing our StateTree
  ///
  /// This Tree manages all of our models
  let tree = ReportedTree(root: CountersList())

  func scene(
    _ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions
  ) {
    guard let scene = (scene as? UIWindowScene) else {
      return
    }
    let mainWindow = UIWindow(windowScene: scene)
    window = mainWindow

    Task {
      try await tree.start()
    }
    Task {
      let root = try await tree.root
      mainWindow.rootViewController = RootViewController(model: root)
    }

    window?.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_: UIScene) { }

  func sceneDidBecomeActive(_: UIScene) { }

  func sceneWillResignActive(_: UIScene) { }

  func sceneWillEnterForeground(_: UIScene) { }

  func sceneDidEnterBackground(_: UIScene) { }

}
