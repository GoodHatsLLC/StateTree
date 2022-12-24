import Foundation
import ModelInterface
import SourceLocation
import Tree

// MARK: - JSONStatePatch

public struct JSONStatePatch: StatePatchType {
  public let identity: SourcePath
  public let jsonString: String
}

// MARK: - JSONTreePatch

public struct JSONTreePatch: TreePatchType {

  public init(time: TimeInterval, statePatches: [SourcePath: JSONStatePatch]) {
    self.time = time
    self.statePatches = statePatches
  }

  public typealias StatePatch = JSONStatePatch
  public let statePatches: [SourcePath: JSONStatePatch]
  public let time: TimeInterval
}

// MARK: - JSONTreePatcher

public struct JSONTreePatcher: TreePatcher {

  public typealias TreePatch = JSONTreePatch

  public func statePatch<State: ModelState>(state: State, for identity: SourcePath) throws
    -> JSONStatePatch
  {
    let jsonString = try jsonCoder.encode(state)
    return JSONStatePatch(identity: identity, jsonString: jsonString)
  }

  public func treePatch(
    time: TimeInterval,
    statePatches: [SourcePath: JSONStatePatch]
  ) throws
    -> JSONTreePatch
  {
    JSONTreePatch(time: time, statePatches: statePatches)
  }

  public func state<State: ModelState>(
    from patch: TreePatch.StatePatch,
    as type: State.Type
  ) throws
    -> State
  {
    try jsonCoder.decode(type, from: patch.jsonString)
  }

  let jsonCoder = JSONStringCoder()

}

// MARK: - JSONTreeStateRecord

public final class JSONTreeStateRecord: TreeStateRecord {

  public init() {}

  public typealias PatchMaker = JSONTreePatcher
  public typealias Player = JSONTreeStatePlayer
  public typealias TreePatch = JSONTreePatch

  public let patchMaker = JSONTreePatcher()
  public var patches: [JSONTreePatch] = []
  public var _temp: [SourcePath: JSONStatePatch] = [:]
  public var errors: [Error] = []

  public func makePlayer() -> JSONTreeStatePlayer {
    JSONTreeStatePlayer(treePatches: patches)
  }

}

// MARK: - JSONTreeStatePlayer

public final class JSONTreeStatePlayer: TreeStatePlayer {

  public init(treePatches: [JSONTreePatch]) {
    self.treePatches = treePatches
  }

  public typealias Patcher = JSONTreePatcher
  public typealias TreePatch = JSONTreePatch

  public var currentFrame: Int? = nil
  public let selection: PublishSubject<Int> = .init()
  public let selectionError: PublishSubject<Error> = .init()
  public let patcher = JSONTreePatcher()
  public let treePatches: [JSONTreePatch]
}
