import SwiftUI

public struct GlyphButton: View {
  public init(glyph: String) {
    self.glyph = glyph
  }

  public let glyph: String
  public var body: some View {
    ZStack {
      Image(systemName: glyph)
        .fontWeight(.medium)
      Color.clear
    }
  }
}
