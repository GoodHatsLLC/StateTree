import StateTreeSwiftUI
import SwiftUI
import ToDoDomain

// MARK: - EditTagView

struct EditTagView: View {
  @TreeNode var tagEditor: TagEditor
  @State var showColorPicker: Bool = false

  var body: some View {
    VStack(alignment: .center) {
      TextField(text: $tagEditor.editingTag.name) {
        Text("tag name")
      }
      HStack {
        Button {
          tagEditor.saveTag()
        } label: {
          Label("Save", systemImage: "checkmark.circle")
            .labelStyle(.iconOnly)
        }
        Button {
          tagEditor.dismiss()
        } label: {
          Label("Cancel", systemImage: "xmark.circle")
            .labelStyle(.iconOnly)
        }
        Button {
          tagEditor.deleteTag()
        } label: {
          Label("Delete", systemImage: "trash")
            .labelStyle(.iconOnly)
        }
        Button {
          showColorPicker = true
        } label: {
          Label("Change Color", systemImage: "paintpalette")
            .labelStyle(.iconOnly)
        }
      }
    }.padding(0.5.su)
      .popover(isPresented: $showColorPicker, attachmentAnchor: .point(.top)) {
        ColorPicker("Tag Color", selection: $tagEditor.$editingTag.colour.swiftUI)
          .padding(1.su)
      }
  }
}
