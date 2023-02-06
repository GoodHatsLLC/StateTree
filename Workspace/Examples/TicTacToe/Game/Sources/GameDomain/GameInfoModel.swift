import Foundation
import StateTree

// MARK: - GameInfoModel

public struct GameInfoModel: Node {

  // MARK: Lifecycle

  public init(
    authentication: Projection<Authentication>,
    logoutFunc: @escaping () -> Void
  ) {
    _authentication = authentication
    self.logoutFunc = logoutFunc
  }

  // MARK: Public

  @Route(GameModel.self) public var game
  @Value public private(set) var lastResult: GameResult? = nil

  public var rules: some Rules {
    if let player = $activePlayer.compact() {
      $game.route {
        GameModel(
          currentPlayer: player,
          finishHandler: finishHandler(result:)
        )
      }
    }
  }

  public func name(of player: Player) -> String {
    switch player {
    case .X:
      return authentication.playerX
    case .O:
      return authentication.playerO
    }
  }

  // MARK: Internal

  @Projection var authentication: Authentication
  @Scope var scope
  @Value var score: Score = .init()
  @Value var activePlayer: Player? = nil
  let logoutFunc: () -> Void

}

extension GameInfoModel {

  // MARK: Public

  public var xScore: Int {
    score.x
  }

  public var oScore: Int {
    score.o
  }

  public func startGame() {
    if case .win(let player) = lastResult {
      activePlayer = player.other()
    } else {
      activePlayer = Bool.random() ? .X : .O
    }
  }

  public func resetScore() {
    activePlayer = nil
    score = .init()
  }

  public func logout() {
    logoutFunc()
  }

  // MARK: Private

  private func finishHandler(result: GameResult) {
    $scope.transaction {
      if case .win(let winner) = result {
        switch winner {
        case .X:
          score.x += 1
        case .O:
          score.o += 1
        }
      }
      lastResult = result
      activePlayer = nil
    }
  }

}
