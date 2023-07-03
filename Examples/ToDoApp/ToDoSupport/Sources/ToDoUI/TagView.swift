import StateTreeSwiftUI
import SwiftUI
import ToDoDomain
import UIComponents

// MARK: - TagView

struct TagView: View {

  @TreeNode var manager: ToDoManager

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      List(manager.tagList, id: \.id, selection: $manager.$selectedTag) { tag in
        NavigationLink(value: tag.id) {
          Label(tag.name, systemImage: "tag")
            .labelStyle(.titleOnly)
            .padding([.horizontal], 1.su)
            .padding([.vertical], 0.25.su)
            .background(Capsule().fill(tag.colour.swiftUI))
        }
      }
      if let tagEditor = $manager.$tagEditor {
        EditTagView(tagEditor: tagEditor)
      }
      Spacer()
      VStack(alignment: .leading, spacing: 0) {
        Divider()
        HStack(spacing: 0) {
          Button {
            manager.addTag()
          } label: {
            GlyphButton(glyph: "plus")
              .frame(width: 3.su, height: 3.su)
          }
          Divider()
          Button(action: {
            if let tagSelection = manager.selectedTag {
              manager.editTag(id: tagSelection)
            }
          }) {
            GlyphButton(glyph: "square.and.pencil")
              .frame(width: 3.su, height: 3.su)
          }
          Spacer()
        }
        .frame(height: 3.su)
        .buttonStyle(.borderless)
      }
    }
  }

}
