import Emitter
import Foundation
import Model
import ModelInterface
import Node
import SourceLocation
import Utilities

@_exported import class Emitter.PublishSubject

// MARK: - TreePatcher

/// A type able to create patches of tree state
public protocol TreePatcher {
  associatedtype TreePatch: TreePatchType
  /// Create a patch for a specific model's update
  func statePatch<State: ModelState>(state: State, for identity: SourcePath) throws
    -> TreePatch.StatePatch
  /// Group model updates into a full Tree state patch
  func treePatch(
    time: TimeInterval,
    statePatches: [SourcePath: TreePatch.StatePatch]
  ) throws -> TreePatch
  func state<State: ModelState>(
    from patch: TreePatch.StatePatch,
    as type: State.Type
  ) throws -> State
}
