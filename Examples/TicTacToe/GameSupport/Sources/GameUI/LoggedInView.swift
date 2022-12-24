import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - LoggedInView

public struct LoggedInView: View {

  public init(model: GameInfoModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      if let game = model.game {
        GameView(model: game)
      } else {
        ScoreBoardView(model: model)
      }
    }
  }

  @ObservedModel var model: GameInfoModel

}

// MARK: - LoggedInView_Previews

struct LoggedInView_Previews: PreviewProvider {
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
