import Foundation
import StateTree

// MARK: - GameInfoModel

public struct GameInfoModel: Model {

  public init(
    store: Store<GameInfoModel>,
    logout: Behavior<Void>
  ) {
    self.store = store
    logoutBehavior = logout
  }

  public struct State: ModelState {
    public init(authentication: Authentication) {
      self.authentication = authentication
    }

    var authentication: Authentication
    var score: Score = .init()
    var lastResult: GameResult? = nil
    var activePlayer: Player? = nil
  }

  public let store: Store<Self>

  @Route<GameModel> public var game

  @RouteBuilder
  public func route(state: Projection<State>) -> some Routing {
    if let state = state.activePlayer.compact() {
      $game
        .route(into: .init(firstPlayer: state.value)) { store in
          .init(store: store, finishHandler: finishHandler(result:))
        }
    }
  }

  @DidActivate<Self> var startOne = { _ in

    Task {
      debugPrint("GAMEINFO: startOne")
    }
  }

  @DidActivate<Self> var startTwo = { _ in
    Behavior {
      debugPrint("GAMEINFO: startTwo")
    }
  }

  @DidActivate<Self> var startThree = { _ in

    debugPrint("GAMEINFO: startThree")
  }

  // MARK: Private

  private let logoutBehavior: Behavior<()>

}

extension GameInfoModel {

  public var lastResult: GameResult? {
    store.read.lastResult
  }

  public var xScore: Int {
    store.read.score.x
  }

  public var oScore: Int {
    store.read.score.o
  }

  public func startGame() {
    store.transaction { state in
      if case .win(let player) = state.lastResult {
        state.activePlayer = player.other()
      } else {
        state.activePlayer = Bool.random() ? .X : .O
      }
    }
  }

  public func resetScore() {
    store.transaction { state in
      state.activePlayer = nil
      state.score = .init()
    }
  }

  public func logout() {
    logoutBehavior
      .run(with: self)
  }

  private func finishHandler(result: GameResult) {
    store.transaction { state in
      if case .win(let winner) = result {
        switch winner {
        case .X:
          state.score.x += 1
        case .O:
          state.score.o += 1
        }
      }
      state.lastResult = result
      state.activePlayer = nil
    }
  }

}
