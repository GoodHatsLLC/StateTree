import Foundation
import SourceLocation

// MARK: - StatePatchType

public protocol StatePatchType: Codable {}

// MARK: - TreePatchType

public protocol TreePatchType: Codable {
  associatedtype StatePatch: StatePatchType
  var statePatches: [SourcePath: StatePatch] { get }
  var time: TimeInterval { get }
  init(time: TimeInterval, statePatches: [SourcePath: StatePatch])
}
