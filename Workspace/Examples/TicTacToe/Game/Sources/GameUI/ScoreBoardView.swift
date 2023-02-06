import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - ScoreBoardView

struct ScoreBoardView: View {

  // MARK: Lifecycle

  public init(model: TreeNode<GameInfoModel>) {
    _model = model
  }

  // MARK: Internal

  @TreeNode var model: GameInfoModel

  var body: some View {
    VStack(alignment: .center, spacing: 1.su) {
      if let last = model.lastResult {
        VStack {
          Text("\(last.winner == nil ? "🥲" : "🥳")")
            .font(.largeTitle.monospaced())
          Text("\(last.winner?.icon ?? "Nobody") Wins!")
            .font(.largeTitle.monospaced())
          Divider()
        }
      }
      HStack {
        VStack(alignment: .leading, spacing: 1.su) {
          Text("Score")
            .font(.title.monospaced())
          Text("\(Player.X.icon) \(model.name(of: .X)): \t\(model.xScore)")
            .font(.body.monospaced())
          Text("\(Player.O.icon) \(model.name(of: .O)): \t\(model.oScore)")
            .font(.body.monospaced())
        }
        Divider()
          .padding()
        VStack(alignment: .trailing) {
          Text("")
          Button("🏁 Start") {
            model.startGame()
          }
          .font(.body.monospaced())
          Button("↪️ Reset") {
            model.resetScore()
          }
          .font(.body.monospaced())
          Button("✌️ Logout") {
            model.logout()
          }
        }
      }
      .padding()
    }
    .scaledToFit()
  }

}

// MARK: - ScoreBoardView_Previews

struct ScoreBoardView_Previews: PreviewProvider {

  @PreviewNode static var gameInfo = GameInfoModel(
    authentication: .stored(.init(playerX: "xPlayer", playerO: "oPlayer", token: "")),
    logoutFunc: { }
  )

  static var previews: some View {
    ScoreBoardView(
      model: $gameInfo
    ).fixedSize()
  }

}
