import Disposable
import StateTree

// MARK: - WeakRef

struct WeakRef<T: AnyObject> {
  weak var ref: T?
}

extension Task {
  func stage(on stage: DisposableStage) {
    Disposables.make {
      self
    }.stage(on: stage)
  }
}

extension Tree {
  func run(on stage: DisposableStage) async {
    Task {
      await self.run()
    }.stage(on: stage)
    await self.awaitRunning()
  }
}
