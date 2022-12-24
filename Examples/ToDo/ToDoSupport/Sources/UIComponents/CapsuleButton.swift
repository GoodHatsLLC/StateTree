import SwiftUI

// MARK: - CapsuleButton

public struct CapsuleButton: View {
  public init(
    title: String,
    systemImage: String,
    isEnabled: Bool = true,
    action: @escaping () -> Void
  ) {
    self.systemImage = systemImage
    self.isEnabled = isEnabled
    self.action = action
    self.title = title
  }

  public var body: some View {
    Button(action: action) {
      Label(title, systemImage: systemImage)
    }
    .buttonStyle(DropShadowButton())
    .disabled(!isEnabled)
    .fixedSize()
  }

  private let systemImage: String
  private let title: String

  private let action: () -> Void
  private let isEnabled: Bool

}

// MARK: - DropShadowButton

struct DropShadowButton: ButtonStyle {

  func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .buttonStyle(.plain)
      .labelStyle(.iconOnly)
      .padding(4)
      .background {
        Capsule(style: .continuous)
          .stroke(style: StrokeStyle(lineWidth: 1))
          .opacity(0.05)
      }
      .background {
        Capsule(style: .continuous)
          .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
          .foregroundStyle(
            .ultraThickMaterial
              .shadow(
                .drop(
                  color: .black.opacity(0.3),
                  radius: 1,
                  x: configuration.isPressed ? 0 : 1,
                  y: configuration.isPressed ? 0 : 1
                )
              )
              .shadow(
                .drop(
                  color: .white.opacity(0.7),
                  radius: 1,
                  x: configuration.isPressed ? 0 : -1,
                  y: configuration.isPressed ? 0 : -1
                )
              )
          )
      }
      .clipShape(
        Capsule(style: .continuous)
          .scale(x: 1.su, y: 1.su, anchor: .center)
      )
      .padding([.horizontal], 2)
      .padding([.vertical], 4)
      .frame(maxHeight: .infinity)
      .fixedSize()
  }
}

// MARK: - CapsuleButton_Previews

struct CapsuleButton_Previews: PreviewProvider {

  static var previews: some View {
    VStack {
      CapsuleButton(
        title: "idk",
        systemImage: "OtherTag"
      ) {}
      .padding(8.su)
      CapsuleButton(
        title: "add",
        systemImage: "+"
      ) {}
      .padding(8.su)
      CapsuleButton(
        title: "remove",
        systemImage: "-"
      ) {}
      .padding(8.su)
    }
  }
}
