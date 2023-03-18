import Behaviors
import Disposable
import Emitter
import TreeActor
import XCTest

// MARK: - DisposableStage + BehaviorScoping

extension DisposableStage: BehaviorScoping {
  public func own(_ disposable: some Disposable) {
    disposable.stage(on: self)
  }
}

// MARK: - TestError

struct TestError: Error { }
