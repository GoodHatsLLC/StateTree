import Foundation
import StateTree

// MARK: - GameModel

public struct GameModel: Model {

  public init(
    store: Store<Self>,
    finishHandler: @escaping @MainActor (GameResult) -> Void
  ) {
    self.store = store
    self.finishHandler = finishHandler
  }

  public struct State: ModelState {
    public init(
      firstPlayer: Player
    ) {
      currentPlayer = firstPlayer
    }

    var board: BoardState = .init()
    var currentPlayer: Player = .X
  }

  public let store: Store<Self>

  public var currentPlayer: Player {
    store.read.currentPlayer
  }

  public var grid: [[BoardState.Cell]] {
    store.read.board.playedMoves
  }

  @RouteBuilder
  public func route(state _: Projection<State>) -> some Routing {
    VoidRoute()
  }

  public func play(row: Int, col: Int) {
    store
      .transaction { state in
        do {
          try state.board.play(state.currentPlayer, row: row, col: col)
        } catch { return }

        state.currentPlayer = (state.currentPlayer == .X) ? .O : .X
      }
    if store.read.board.boardFilled || store.read.board.winner != nil {
      finishHandler(GameResult(winner: store.read.board.winner))
    }
  }

  private let finishHandler: @MainActor (GameResult) -> Void

}
