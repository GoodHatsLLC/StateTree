import Foundation
import StateTreeSwiftUI
import SwiftUI
import ToDoDomain
import UIComponents

// MARK: - SelectedToDoView

struct SelectedToDoView: View {

  // MARK: Public

  public var body: some View {
    ZStack {
      VStack(alignment: .leading) {
        TextField(
          "",
          text: $selected.title,
          prompt: Text("Title…")
        )
        .textFieldStyle(.plain)
        .foregroundStyle(.selection)
        .font(.largeTitle)
        HStack {
          HStack(spacing: 0.5.su) {
            Toggle("", isOn: $selected.isCompleted)
              .tint(.accentColor)
              .toggleStyle(.switch)
              .padding([.trailing], 0.5.su)
            Divider()
            Section {
              DatePicker(
                "Due on:",
                selection: Binding($selected.dueDate) ??
                  .init(get: { Date() }, set: { selected.dueDate = $0 }),
                displayedComponents: [.date]
              )
              .datePickerStyle(.compact)
              Button {
                selected.dueDate = nil
              } label: {
                Label(
                  "Clear Date",
                  systemImage: "xmark"
                ).labelStyle(.iconOnly)
              }
            }.opacity(selected.dueDate == nil ? 0.5 : 1)
            Divider()
            Button {
              showTagSelector = true
            } label: {
              Label(
                "Add Tag",
                systemImage: "tag"
              ).labelStyle(.iconOnly)
            }
            .popover(isPresented: $showTagSelector) {
              TagSelectionView(
                tagSelector: $selected.$tagSelector!,
                isDisplayed: $showTagSelector
              )
              .frame(width: 100, height: 200)
            }
          }
          .fixedSize()
          ScrollView(.horizontal) {
            Grid(alignment: .center, verticalSpacing: 0) {
              GridRow {
                ForEach(selected.tags.sorted { $0.name < $1.name }) { tag in
                  HStack {
                    Label(tag.name, systemImage: "tag")
                      .labelStyle(.titleOnly)
                      .padding([.horizontal], 1.su)
                      .padding([.vertical], 0.25.su)
                      .background(Capsule().fill(tag.colour.swiftUI))
                  }
                }
              }
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity)
          }
        }
        TextEditor(text: $selected.note)
          .font(.body.monospaced())
          .lineSpacing(0.25.su)
          .padding(1.su)
      }
      .padding(1.su)
    }
  }

  // MARK: Internal

  @State var showTagSelector: Bool = false
  @TreeNode var selected: SelectedToDo

}

// MARK: - Int + Identifiable

extension Int: Identifiable {
  public var id: Self { self }
}
