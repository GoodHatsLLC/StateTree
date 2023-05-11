import Foundation

// MARK: - TreeLifecycleEvent
public enum TreeLifecycleEvent: Codable, CustomStringConvertible {
  public var description: String {
    switch self {
    case .started(let treeID):
      return "started tree (id: \(treeID)"
    case .stopped(let treeID):
      return "stopped tree (id: \(treeID)"
    }
  }

  public var treeID: UUID {
    switch self {
    case .started(let treeID):
      return treeID
    case .stopped(let treeID):
      return treeID
    }
  }

  case started(treeID: UUID)
  case stopped(treeID: UUID)
}
