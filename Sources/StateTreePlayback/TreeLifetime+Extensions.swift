import Emitter
import Foundation
import StateTree

extension TreeLifetime {

  // MARK: Public

  /// Create a ``Recorder`` able to record this tree's new frames, prefixing its records with any
  /// passed frames.
  public func recorder(frames: [StateFrame] = []) -> Recorder<N> {
    Recorder(lifetime: self, frames: frames)
  }

  /// Create a ``Player`` able to re-play the given frames.
  public func player(frames: [StateFrame]) throws -> Player<N> {
    try Player(lifetime: self, frames: frames)
  }

  // MARK: Internal

  /// A `nonisolated` snapshot accessor that can be used in an emitter chain.
  nonisolated func stateFrameSnapshot() -> some Emitter<StateFrame> {
    Emitters.create(StateFrame.self) { emit in
      Task { @TreeActor in
        emit(
          .value(
            StateFrame(record: snapshot())
          )
        )
        emit(.finished)
      }
    }
  }
}
