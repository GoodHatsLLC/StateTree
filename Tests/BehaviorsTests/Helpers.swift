import Behaviors
import Disposable
import Emitter
import TreeActor
import XCTest

// MARK: - DisposableStage + Scoping

extension DisposableStage: Scoping {
  public func own(_ disposable: some Disposable) {
    disposable.stage(on: self)
  }
}

// MARK: - TestError

struct TestError: Error { }
