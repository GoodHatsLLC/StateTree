import SwiftUI

// MARK: - CapsuleSearchField

public struct CapsuleSearchField: View {
  public init(
    text: Binding<String>,
    prompt: String
  ) {
    self.text = text
    self.prompt = prompt
  }

  let text: Binding<String>
  let prompt: String

  public var body: some View {
    TextField(
      "",
      text: text,
      prompt: Text(prompt)
    )
    .textFieldStyle(.plain)
    .focused($focussed)
    .font(.callout.monospaced())
    .padding([.vertical], 4)
    .padding([.horizontal], 8)
    .labelStyle(.titleOnly)
    .background {
      Capsule(style: .continuous)
        .stroke(
          style: StrokeStyle(
            lineWidth: 1
          )
        )
        .opacity(0.05)
    }
    .background {
      Capsule(style: .continuous)
        .background(.white.opacity(0.5))
        .foregroundStyle(
          .background
            .shadow(
              .inner(
                color: .black.opacity(0.5),
                radius: 1,
                x: 1,
                y: 1
              )
            )
            .shadow(
              .inner(
                color: .white.opacity(0.6),
                radius: 1,
                x: -1,
                y: -1
              )
            )
        )
    }
    .clipShape(Capsule(style: .continuous))
    .frame(maxWidth: .infinity)
    .padding(1.su)
  }

  @FocusState var focussed

}

// MARK: - Previews_CapsuleSearchField_Previews

struct Previews_CapsuleSearchField_Previews: PreviewProvider {

  struct Editable: View {
    @State var string = "Some Tag"
    var body: some View {
      CapsuleSearchField(
        text: $string,
        prompt: "Prompt…"
      )
    }
  }

  static var previews: some View {
    VStack {
      Editable()
        .padding(8.su)
    }
  }
}
