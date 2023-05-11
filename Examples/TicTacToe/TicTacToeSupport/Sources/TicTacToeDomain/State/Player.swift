import StateTree

// MARK: - Player

public enum Player: Codable, Hashable {
  case X
  case O

  func other() -> Player {
    switch self {
    case .O: return .X
    case .X: return .O
    }
  }
}
