import Emitter
import Foundation
import StateTree

extension Tree {

  /// Create a ``Recorder`` able to record this tree's new frames, prefixing its records with any
  /// passed frames.
  public func recorder(frames: [StateFrame] = []) -> Recorder<N> {
    Recorder(tree: self, frames: frames)
  }

  /// Create a ``Player`` able to re-play the given frames.
  public func player(frames: [StateFrame]) throws -> Player<N> {
    try Player(lifetime: self, frames: frames)
  }

}
