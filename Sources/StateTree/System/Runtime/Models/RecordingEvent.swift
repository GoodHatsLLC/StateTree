import Foundation

public enum RecordingEvent: Codable, CustomStringConvertible {
  public var description: String {
    switch self {
    case .started(let recorderID):
      return "started recorder (id: \(recorderID))"
    case .stopped(let recorderID):
      return "stopped recorder (id: \(recorderID))"
    }
  }

  case started(recorderID: UUID)
  case stopped(recorderID: UUID)
}
