import Foundation
import TreeState

public enum RecordingEvent: TreeState, CustomStringConvertible {
  public var description: String {
    switch self {
    case .started(let recorderID):
      return "started recorder (id: \(recorderID)"
    case .stopped(let recorderID):
      return "started recorder (id: \(recorderID)"
    }
  }

  case started(recorderID: UUID)
  case stopped(recorderID: UUID)
}
