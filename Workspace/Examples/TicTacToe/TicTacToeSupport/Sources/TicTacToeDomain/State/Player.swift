import StateTree

// MARK: - Player

public enum Player: TreeState {
  case X
  case O

  func other() -> Player {
    switch self {
    case .O: .X
    case .X: .O
    }
  }
}
