import Foundation
import StateTree

// MARK: - GameModel

public struct GameModel: Node {

  // MARK: Lifecycle

  public init(
    currentPlayer: Projection<Player>,
    board: BoardState = .init(),
    finishHandler: @escaping @TreeActor (GameResult) -> Void
  ) {
    _currentPlayer = currentPlayer
    self.finishHandler = finishHandler
    self.board = board
  }

  // MARK: Public

  @Projection public var currentPlayer: Player

  public var grid: [[BoardState.Cell]] {
    board.cells
  }

  public var rules: some Rules {
    OnChange(board) { board in
      if board.boardFilled || board.winner != nil {
        finishHandler(board.winner.map { .win($0) } ?? .draw)
      }
    }
  }

  public func play(row: Int, col: Int) {
    $scope.transaction {
      do {
        try board.play(currentPlayer, row: row, col: col)
      } catch { return }
      currentPlayer = (currentPlayer == .X) ? .O : .X
    }
  }

  // MARK: Internal

  @Scope var scope
  @Value var board: BoardState = .init()
  let finishHandler: @TreeActor (GameResult) -> Void

}
