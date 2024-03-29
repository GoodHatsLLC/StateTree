import Foundation
import StateTree

// MARK: - GameModel

public struct GameNode: Node {

  // MARK: Lifecycle

  public init(
    currentPlayer: Projection<Player>,
    board: BoardState = .init(),
    finishHandler: @escaping (GameResult) -> Void
  ) {
    _currentPlayer = currentPlayer
    self.finishHandler = finishHandler
    self.board = board
  }

  // MARK: Public

  @Projection public private(set) var currentPlayer: Player

  public var grid: [[BoardState.Cell]] {
    board.cells
  }

  public var rules: some Rules {
    OnUpdate(board) { board in
      if board.boardFilled || board.winner != nil {
        finishHandler(board.winner.map { .win($0) } ?? .draw)
      }
    }
  }

  public func play(row: Int, col: Int) {
    $scope.transaction {
      try? board.play(currentPlayer, row: row, col: col)
      currentPlayer = (currentPlayer == .X) ? .O : .X
    }
  }

  // MARK: Private

  @Scope private var scope
  @Value private var board: BoardState = .init()

  private let finishHandler: (GameResult) -> Void

}
