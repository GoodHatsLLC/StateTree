import StateTreeSwiftUI
import SwiftUI
import TicTacToeDomain

// MARK: - LoggedInView

struct LoggedInView: View {

  var body: some View {
    VStack {
      if let game = $model.$game {
        GameView(model: game)
      } else {
        ScoreBoardView(model: $model)
      }
    }
  }

  @TreeNode var model: GameInfoModel

}

// MARK: - LoggedInView_Previews

struct LoggedInView_Previews: PreviewProvider {

  @PreviewNode static var gameInfo = GameInfoModel(
    authentication: .stored(
      .init(
        playerX: "one",
        playerO: "two",
        token: "password"
      )
    ),
    logoutFunc: { }
  )

  static var previews: some View {
    LoggedInView(model: $gameInfo)
      .fixedSize()
  }
}
