import Foundation
import StateTree

// MARK: - GameInfoNode

public struct GameInfoNode: Node {

  // MARK: Lifecycle

  public init(
    authentication: Projection<Authentication>,
    logoutFunc: @escaping () -> Void
  ) {
    _authentication = authentication
    self.logoutFunc = logoutFunc
  }

  // MARK: Public

  @Route public var game: GameNode? = nil
  @Value public private(set) var lastResult: GameResult? = nil

  public var rules: some Rules {
    if let player = $activePlayer.compact() {
      Serve(
        GameNode(
          currentPlayer: player,
          finishHandler: finishHandler(result:)
        ),
        at: $game
      )
    }
  }

  // MARK: Internal

  @Value var score: Score = .init()
  @Value var activePlayer: Player? = nil

  // MARK: Private

  @Projection private var authentication: Authentication
  @Scope private var scope
  private let logoutFunc: () -> Void

}

extension GameInfoNode {

  // MARK: Public

  public var xName: String {
    authentication.playerX
  }

  public var oName: String {
    authentication.playerO
  }

  public var xScore: Int {
    score.x
  }

  public var oScore: Int {
    score.o
  }

  public func startGame() {
    activePlayer = activePlayer?.other() ?? (Bool.random() ? .X : .O)
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
