import Emitter
import Foundation
import Model
import ModelInterface
import Node
import SourceLocation
import Utilities

@_exported import class Emitter.PublishSubject

// MARK: - TreeStateRecord

/// A type providing a ``TreePatcher`` and the storage require to use it.
@MainActor
public protocol TreeStateRecord: AnyObject {
  associatedtype TreePatch: TreePatchType
  associatedtype PatchMaker: TreePatcher where PatchMaker.TreePatch == TreePatch
  associatedtype Player: TreeStatePlayer where Player.TreePatch == TreePatch
  var patchMaker: PatchMaker { get }
  var errors: [Error] { get set }
  var _temp: [SourcePath: TreePatch.StatePatch] { get set }
  var patches: [PatchMaker.TreePatch] { get set }
}

extension TreeStateRecord {

  public func makePlayer() -> Player {
    Player(treePatches: patches)
  }

  public func accumulateStatePatch<State: ModelState>(state: State, for identity: SourcePath) {
    do {
      try _temp[identity] = patchMaker.statePatch(state: state, for: identity)
    } catch {
      errors.append(error)
    }
  }

  public func flushStatePatches(time: TimeInterval) {
    do {
      try patches.append(
        patchMaker.treePatch(
          time: time, statePatches: _temp
        )
      )
    } catch {
      errors.append(error)
    }
    _temp = [:]
  }
}
