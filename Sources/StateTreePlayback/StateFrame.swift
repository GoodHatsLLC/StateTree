import Foundation
import StateTree

// MARK: - StateFrame

/// A snapshot of the StateTree at a moment in time
///
/// `StateFrames` contain the `TreeStateRecord` state and metadata
public struct StateFrame: TreeState, Identifiable {

  // MARK: Lifecycle

  init(data: FrameData) {
    self.id = .init()
    self.timestamp = .init()
    self.data = data
  }

  // MARK: Public

  public enum FrameData: TreeState {
    case meta(TreeEvent)
    case update(TreeEvent, TreeStateRecord)
  }

  public let id: UUID
  public let data: FrameData
  public let timestamp: Date

  public var event: TreeEvent {
    switch data {
    case .meta(let treeEvent):
      return treeEvent
    case .update(let treeEvent, _):
      return treeEvent
    }
  }

  public var state: TreeStateRecord? {
    switch data {
    case .meta:
      return nil
    case .update(_, let treeStateRecord):
      return treeStateRecord
    }
  }

}
