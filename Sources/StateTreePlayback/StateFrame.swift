import Foundation
import StateTree

// MARK: - StateFrame

/// A snapshot of the StateTree at a moment in time
///
/// `StateFrames` contain the `TreeStateRecord` state and metadata
public struct StateFrame: TreeState, Identifiable {
  init(record: TreeStateRecord, event: TreeEvent) {
    self.id = .init()
    self.date = .init()
    self.state = record
    self.event = event
  }

  public let id: UUID
  public let event: TreeEvent
  public let state: TreeStateRecord
  public let date: Date
}
