import Disposable
import StateTree

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
