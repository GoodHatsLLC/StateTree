import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - ScoreBoardView

public struct ScoreBoardView: View {

  public init(model: GameInfoModel) {
    self.model = model
  }

  public var body: some View {
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
          Text("\(Player.O.icon): \(model.oScore)")
            .font(.body.monospaced())
          Text("\(Player.X.icon): \(model.xScore)")
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

  @ObservedModel var model: GameInfoModel

}

// MARK: - ScoreBoardView_Previews

struct ScoreBoardView_Previews: PreviewProvider {
  static var previews: some View {
    ScoreBoardView(
      model: .preview(
        state: .init(
          authentication: .init()
        )
      ) { store in
        GameInfoModel(store: store, logout: .fail())
      }
    )
  }
}
