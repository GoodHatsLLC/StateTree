import Foundation

// MARK: - _StateRecorder

protocol _StateRecorder<State> {
  associatedtype State: ModelState
  func accumulateState(with accumulator: StateAccumulator) throws
  func apply(state: State) throws
}

// MARK: - _Recorder

@MainActor
public struct _Recorder<State: ModelState> {
  init(_ recorder: some _StateRecorder<State>) {
    accumulateFunc = { try recorder.accumulateState(with: $0) }
    applyFunc = { try recorder.apply(state: $0) }
  }

  public func accumulateState(with accumulator: StateAccumulator) throws {
    try accumulateFunc(accumulator)
  }

  public func apply(state: State) throws {
    try applyFunc(state)
  }

  private let accumulateFunc: (StateAccumulator) throws -> Void
  private let applyFunc: (State) throws -> Void
}
