import GameDomain
import StateTreeSwiftUI
import SwiftUI

// MARK: - LoggedOutView

public struct LoggedOutView: View {

  public init(model: UnauthenticatedModel) {
    self.model = model
  }

  public var body: some View {
    Form {
      Section {
        VStack(alignment: .leading) {
          HStack {
            Text("TicTacToe")
              .font(.title)
            Spacer()
            Text("❎ ⚔️ 🅾️")
              .font(.title)
          }
          TextField("User", text: $userName)
            .truncationMode(.tail)
            .textContentType(.username)
            .font(.body.monospaced())
            .onSubmit {
              submit()
            }
          TextField("Password", text: $password)
            .truncationMode(.tail)
            .textContentType(.password)
            .font(.body.monospaced())
            .popover(
              isPresented: model.store.projection.shouldHint.binding()
            ) {
              Text("Hint: Yolo123")
                .padding()
            }
            .onSubmit {
              submit()
            }
          Button("Login") {
            submit()
          }
        }
      }
    }
    .padding()
  }

  @ObservedModel var model: UnauthenticatedModel

  @State var userName = ""
  @State var password = ""

  private func submit() {
    model
      .authenticate(
        username: userName,
        password: password
      )
  }

}

// MARK: - LoginView_Previews

struct LoginView_Previews: PreviewProvider {

  static var previews: some View {
    LoggedOutView(
      model: .preview(
        state: .init(
          authentication: nil,
          shouldHint: false
        )
      ) { store in
        UnauthenticatedModel(store: store)
      }
    ).previewLayout(.sizeThatFits)
  }
}
