import StateTreeSwiftUI
import SwiftUI
import TicTacToeDomain

// MARK: - ScoreBoardView

struct ScoreBoardView: View {

  @TreeNode var model: GameInfoNode

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
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 1.su) {
          Text("Score")
            .font(.title.monospaced())
          Text("\(Player.X.icon) \(model.xName): \t\(model.xScore)")
            .font(.body.monospaced())
          Text("\(Player.O.icon) \(model.oName): \t\(model.oScore)")
            .font(.body.monospaced())
        }
        Divider()
          .padding()
        VStack(alignment: .trailing, spacing: 1.su) {
          Text("")
            .font(.title.monospaced())
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

  @PreviewNode static var gameInfo = GameInfoNode(
    authentication: .stored(.init(playerX: "xPlayer", playerO: "oPlayer", token: "")),
    logoutFunc: { }
  )

  static var previews: some View {
    ScoreBoardView(
      model: $gameInfo
    ).fixedSize()
  }

}
