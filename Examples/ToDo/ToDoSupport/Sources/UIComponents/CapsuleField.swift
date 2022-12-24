import SwiftUI

// MARK: - CapsuleField

public struct CapsuleField: View, Identifiable {
  public init(
    id: some Hashable,
    text: Binding<String>,
    onExit: @escaping (_ hasContent: Bool) -> Void = { _ in }
  ) {
    self.id = id
    self.text = text
    self.onExit = onExit
  }

  public let id: AnyHashable
  public let text: Binding<String>

  public var body: some View {
    TextField("", text: text, prompt: Text("Tag…"))
      .focused($focussed)
      .font(.footnote.monospaced())
      .padding(4)
      .textFieldStyle(.plain)
      .labelStyle(.titleOnly)
      .background {
        Capsule(style: .continuous)
          .stroke(style: StrokeStyle(lineWidth: 1))
          .opacity(0.05)
      }
      .background {
        Capsule(style: .continuous)
          .background(
            text.wrappedValue.isEmpty || focussed
              ? .clear
              : Pastel.hash(
                from: text.wrappedValue
              )
          )
          .foregroundStyle(
            .thickMaterial
              .shadow(
                .inner(
                  color: .black.opacity(0.3),
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
      .clipShape(
        Capsule(style: .continuous)
      )
      .padding([.horizontal], 2)
      .padding([.vertical], 2)
      .frame(minWidth: 60)
      .frame(maxHeight: .infinity)
      .fixedSize()
      .onChange(of: focussed) { isFocussed in
        if !isFocussed {
          onExit?(!text.wrappedValue.isEmpty)
        }
      }
  }

  @FocusState var focussed

  private let onExit: ((Bool) -> Void)?

}

// MARK: - Previews_Capsule_Previews

struct Previews_Capsule_Previews: PreviewProvider {

  struct Editable: View {
    @State var string = "Some Tag"
    var body: some View {
      CapsuleField(
        id: UUID(),
        text: $string,
        onExit: { _ in }
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
