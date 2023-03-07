import StateTree

// MARK: - BoardState

public struct BoardState: TreeState {

  // MARK: Lifecycle

  public init() {
    self.cells = (Int(0) ..< Int(3)).map { i in
      (Int(0) ..< Int(3)).map { j in
        Cell(id: "\(j)\(i)", player: .none, row: j, col: i)
      }
    }
  }

  // MARK: Public

  public struct Cell: TreeState, Identifiable {
    public var id: String
    public var player: Player?
    public let row: Int
    public let col: Int
  }

  // MARK: Internal

  struct OutOfBoundsError: Error { }
  struct CellOccupiedError: Error { }

  static let wins: [[(Int, Int)]] = [
    [(0, 0), (0, 1), (0, 2)],
    [(1, 0), (1, 1), (1, 2)],
    [(2, 0), (2, 1), (2, 2)],
    [(0, 0), (1, 0), (2, 0)],
    [(0, 1), (1, 1), (2, 1)],
    [(0, 2), (1, 2), (2, 2)],
    [(0, 0), (1, 1), (2, 2)],
    [(0, 2), (1, 1), (2, 0)],
  ]

  var cells: [[Cell]]

  var winner: Player? {
    for winCells in Self.wins {
      let cellContents = winCells.reduce(into: Set<Player?>()) { acc, coordinate in
        acc.insert(cells[coordinate.0][coordinate.1].player)
      }
      if
        cellContents.count == 1,
        let winner = cellContents.compactMap({ $0 }).first
      {
        return winner
      }
    }
    return nil
  }

  var boardFilled: Bool {
    cells
      .flatMap { $0 }
      .compactMap(\.player)
      .count == 9
  }

  mutating func play(_ player: Player, row: Int, col: Int) throws {
    guard
      col < cells.count,
      row < cells[col].count,
      row >= 0,
      col >= 0
    else {
      throw OutOfBoundsError()
    }
    guard cells[col][row].player == nil
    else {
      throw CellOccupiedError()
    }
    cells[col][row].player = player
  }

}
