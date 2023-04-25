import StateTreeSwiftUI
import SwiftUI
import TicTacToeDomain

// MARK: - LoggedOutView

struct LoggedOutView: View {

  // MARK: Internal

  @TreeNode var model: UnauthenticatedModel

  @State var playerX = ""
  @State var playerO = ""
  @State var password = ""

  var body: some View {
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
          TextField("Player x", text: $playerX)
          #if os(iOS)
            .textInputAutocapitalization(.never)
          #endif
            .textFieldStyle(.roundedBorder)
            .truncationMode(.tail)
            .textContentType(.username)
            .font(.body.monospaced())
            .onSubmit {
              submit()
            }
          TextField("Player o", text: $playerO)
          #if os(iOS)
            .textInputAutocapitalization(.never)
          #endif
            .textFieldStyle(.roundedBorder)
            .truncationMode(.tail)
            .textContentType(.username)
            .font(.body.monospaced())
            .onSubmit {
              submit()
            }
          Divider()
            .padding(.horizontal, 2.su)
          TextField("Password", text: $password)
          #if os(iOS)
            .textInputAutocapitalization(.never)
          #endif
            .textFieldStyle(.roundedBorder)
            .truncationMode(.tail)
            .font(.body.monospaced())
            .disabled(model.isLoading)
            .popover(
              isPresented: $model.$shouldHint
            ) {
              Text("Hint: password")
                .padding()
            }
            .onSubmit {
              submit()
            }
          HStack(spacing: 1.su) {
            Button("Login") {
              submit()
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isLoading)
            ProgressView()
              .progressViewStyle(
                CircularProgressViewStyle()
              )
              .opacity(model.isLoading ? 1 : 0)
          }
        }
      }
    }
    .padding()
  }

  // MARK: Private

  private func submit() {
    model
      .authenticate(
        playerX: playerX,
        playerO: playerO,
        password: password
      )
  }

}

// MARK: - LoggedOut_Previews

struct LoggedOut_Previews: PreviewProvider {

  @PreviewNode static var root = UnauthenticatedModel(
    authentication: .stored(
      Authentication(
        playerX: "one",
        playerO: "two",
        token: "abc"
      )
    )
  )

  static var previews: some View {
    LoggedOutView(model: $root)
      .fixedSize()
  }
}
