import StateTree

// MARK: - Score

public struct Score: Codable, Hashable {
  public init(x: Int = 0, o: Int = 0) {
    self.x = x
    self.o = o
  }

  public init() { }
  public var x = 0
  public var o = 0
}

// MARK: - GameResult

public enum GameResult: Codable, Hashable {
  case win(Player)
  case draw

  init(winner: Player?) {
    if let winner {
      self = .win(winner)
    } else {
      self = .draw
    }
  }

  public var winner: Player? {
    switch self {
    case .draw:
      return nil
    case .win(let player):
      return player
    }
  }
}
