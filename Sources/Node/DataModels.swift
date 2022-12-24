import AccessTracker
import Foundation
import ModelInterface
import Projection
import Utilities

struct SourceUpdateTypeError: Error {}

// MARK: - ChangeInProgressDetails

struct ChangeInProgressDetails<State: ModelState>: Identifiable {
  let id: UUID
  let originalState: State
  var newState: State
  var didUpdateRoutes = false
  var isExternal = false

  func getChange() -> Change<State>? {
    .init(
      old: originalState,
      new: newState,
      id: id,
      systemUptime: Uptime.systemUptime
    )
  }
}
