import Foundation
import Node
import SourceLocation
import Utilities

public struct StateAccumulator {

  public init(accumulator: @escaping (_ state: any ModelState, _ identity: SourcePath) -> Void) {
    self.accumulator = accumulator
  }

  func accumulate<State: ModelState>(state: State, identity: SourcePath) {
    accumulator(state, identity)
  }

  private let accumulator: (_ state: any ModelState, _ identity: SourcePath) -> Void
}
