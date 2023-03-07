import Foundation
import StateTree

// MARK: - StateFrame

/// A snapshot of the StateTree at a moment in time
///
/// `StateFrames` contain the `TreeStateRecord` state and metadata
public struct StateFrame: TreeState, Identifiable {
  init(record: TreeStateRecord) {
    self.id = .init()
    self.date = .init()
    self.state = record
  }

  public let id: UUID
  public let state: TreeStateRecord
  public let date: Date
}
