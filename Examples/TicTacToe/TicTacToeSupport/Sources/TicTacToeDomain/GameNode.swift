import Foundation
import StateTree

// MARK: - GameModel

public struct GameNode: Node {

  // MARK: Lifecycle

  public init(
    currentPlayer: Projection<Player>,
    board: BoardState = .init(),
    finishHandler: @escaping (GameResult) async -> Void
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
        try? await Task.sleep(for: .seconds(0.1))
        await finishHandler(board.winner.map { .win($0) } ?? .draw)
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

  private let finishHandler: (GameResult) async -> Void

}
