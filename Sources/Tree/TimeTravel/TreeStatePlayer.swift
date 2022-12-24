import Emitter
import Foundation
import Model
import ModelInterface
import Node
import SourceLocation
import Utilities

@_exported import class Emitter.PublishSubject

// MARK: - TreeStatePlayer

/// A type able to replay tree state patches
@MainActor
public protocol TreeStatePlayer: AnyObject {
  associatedtype TreePatch: TreePatchType
  associatedtype Patcher: TreePatcher where Patcher.TreePatch == TreePatch
  var patcher: Patcher { get }
  var frames: [(index: Int, time: TimeInterval)] { get }
  var selection: PublishSubject<Int> { get }
  var selectionError: PublishSubject<Error> { get }
  var treePatches: [TreePatch] { get }
  var currentFrame: Int? { get set }
  init(treePatches: [TreePatch])
}

extension TreeStatePlayer {

  public var frames: [(index: Int, time: TimeInterval)] {
    treePatches
      .enumerated()
      .map { offset, value in
        (index: offset, time: value.time)
      }
  }

  public func scanTo(proportion: Double) {
    let proportion = max(0.0, min(proportion, 1.0))
    guard frames.count > 0
    else {
      return
    }
    let desiredFrame = Int((proportion * Double(frames.count)).rounded(.down))
    let frame = max(0, min(desiredFrame, frames.count - 1))
    applyFrame(index: frame)
  }

  public func nextFrameScan() -> Double {
    guard frames.count > 0
    else {
      return 0
    }
    let curr = currentFrame ?? 0
    let desiredFrame = curr + 1
    let frame = max(0, min(desiredFrame, frames.count))
    return Double(frame) / Double(frames.count)
  }

  public func previousFrameScan() -> Double {
    guard frames.count > 0
    else {
      return 0
    }
    let curr = currentFrame ?? 0
    let desiredFrame = curr - 1
    let frame = max(0, min(desiredFrame, frames.count))
    return Double(frame) / Double(frames.count)
  }

  public func applyFrame(index: Int) {
    currentFrame = index
    selection.emit(.value(index))
  }

  public func applyFrame(after lastTime: TimeInterval) throws {
    guard
      let frame =
        frames
        .first(where: {
          $0.time > lastTime
        })
    else {
      throw PlayerError.noFrame(after: lastTime)
    }
    selection.emit(.value(frame.index))
  }

  @MainActor
  func apply<M: Model>(index: Int, rootModel: M) throws {
    guard treePatches.count > index
    else {
      throw
        PlayerError
        .missingIndexPatch(index: index)
    }
    let patch = treePatches[index]
    try apply(patch: patch, from: rootModel)
  }

  @MainActor
  func apply<M: Model>(
    patch: TreePatch,
    from model: M
  ) throws {
    guard
      let identity = model.store._storage.routeIdentity,
      let statePatch = patch.statePatches[identity]
    else {
      throw
        PlayerError
        .missingPatch(
          model: model
        )
    }
    do {
      let state =
        try patcher
        .state(
          from: statePatch,
          as: M.State.self
        )
      try model.store._storage._recorder.apply(state: state)
    } catch {
      throw
        PlayerError
        .patchApplicationFailure(
          model: model,
          error: error
        )
    }
    for model in model.submodels {
      try apply(
        patch: patch,
        from: model
      )
    }
  }
}

// MARK: - PlayerError

public enum PlayerError: Error {
  case noFrame(after: TimeInterval)
  case missingIndexPatch(index: Int)
  case missingPatch(model: any Model)
  case patchApplicationFailure(model: any Model, error: Error)
}
