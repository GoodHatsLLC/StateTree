import Disposable
import StateTree

// MARK: - WeakRef

struct WeakRef<T: AnyObject> {
  weak var ref: T?
}

extension Task {
  func stage(on stage: DisposableStage) {
    AutoDisposable {
      self.cancel()
    }
    .stage(on: stage)
  }
}

extension Tree {
  func run(from: TreeStateRecord? = nil, on stage: DisposableStage) async {
    Task {
      let x = await self.run(from: from)
      print(x)
    }.stage(on: stage)
    await awaitRunning()
  }
}
