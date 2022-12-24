import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - GameView

public struct GameView: View {

  public init(model: GameModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      Text("turn: \(model.currentPlayer.icon)")
      Divider()
      HStack {
        Spacer()
        LazyVGrid(
          columns: Array(
            repeating: GridItem(spacing: 16),
            count: model.grid.count
          ),
          alignment: .center,
          spacing: 8
        ) {
          ForEach(model.grid.flatMap { $0 }) { cell in
            Button(cell.icon) {
              model.play(row: cell.row, col: cell.col)
            }
            .buttonStyle(.borderless)
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 20, height: 20)
          }
        }
        .scaledToFit()
        Spacer()
      }
    }
    .padding()
  }

  @ObservedModel var model: GameModel

}

extension BoardState.Cell {
  var icon: String {
    player?.icon ?? "⏹️"
  }
}

extension Player {
  var icon: String {
    switch self {
    case .O: return "🅾️"
    case .X: return "❎"
    }
  }

}

// MARK: - GameView_Previews

struct GameView_Previews: PreviewProvider {

  static var previews: some View {
    GameView(
      model: .preview(
        state: .init(
          firstPlayer: .X
        )
      ) { store in
        GameModel(
          store: store,
          finishHandler: { _ in }
        )
      }
    ).frame(width: 500)
  }
}
