// import StateTreeSwiftUI
// import SwiftUI
// import ToDoDomain
// import UIComponents
//
//// MARK: - SelectedToDoView
//
// public struct SelectedToDoView: View {
//
//  public var body: some View {
//    ZStack {
//      VStack(alignment: .leading) {
//        TextField(
//          "",
//          text: $viewModel.title,
//          prompt: Text("Title…")
//        )
//        .focused($focus, equals: .title)
//        .textFieldStyle(.plain)
//        .foregroundStyle(.selection)
//        .font(.largeTitle)
//
//        HStack(spacing: 0.5.su) {
//          HStack(spacing: 0.5.su) {
//            Toggle("", isOn: $viewModel.isCompleted)
//              .tint(.accentColor)
//              .toggleStyle(.switch)
//              .padding([.trailing], 0.5.su)
//            Divider()
//            DatePicker(
//              "Due Date",
//              selection: viewModel.dateBinding,
//              displayedComponents: [.date]
//            )
//            .focused($focus, equals: .date)
//            .datePickerStyle(.compact)
//            .opacity(viewModel.dateOpacity)
//            CapsuleButton(
//              title: "Clear Date",
//              systemImage: "xmark"
//            ) { viewModel.clearDate() }
//            .opacity(viewModel.dateOpacity)
//            Divider()
//            CapsuleButton(
//              title: "Add",
//              systemImage: "plus"
//            ) {
//              viewModel.newTag()
//            }
//            .opacity(viewModel.canMakeNewTag ? 1 : 0.6)
//            .disabled(!viewModel.canMakeNewTag)
//          }
//          .fixedSize()
//
//          ScrollView(.horizontal) {
//            Grid(alignment: .center, verticalSpacing: 0) {
//              GridRow {
//                ForEach($viewModel.tags) { tag in
//                  CapsuleField(
//                    id: tag.id,
//                    text: tag.title,
//                    onExit: { _ in
//                      switch focus {
//                      case .tag:
//                        break
//                      default: viewModel.clearEmptyTagFields()
//                      }
//                    }
//                  )
//                  .focused(
//                    $focus,
//                    equals: .tag(id: tag.id)
//                  )
//                }
//              }
//            }
//          }
//          .scrollIndicators(.hidden)
//          .frame(maxWidth: .infinity)
//        }
//
//        VStack(alignment: .leading) {
//          TextEditor(text: $viewModel.note)
//            .font(.body.monospaced())
//            .lineSpacing(0.25.su)
//            .focused($focus, equals: .note)
//        }
//      }
//      .frame(maxWidth: .infinity)
//    }
//    .padding(8)
//    .onReceive(viewModel.focusProposer.selectedFocus) { focus in
//      self.focus = focus
//    }
//  }
//
//  @ObservedObject var viewModel: SelectedToDoViewModel
//  @FocusState var focus: AppFocus.SelectedFocus?
// }
//
//// MARK: - ToDoView_Previews
//
// struct ToDoView_Previews: PreviewProvider {
//  static var previews: some View {
//    SelectedToDoView(
//      viewModel: .preview(state: .previewState) { store in
//        SelectedToDo(store: store)
//      } viewModel: { model in
//        SelectedToDoViewModel(
//          model: model,
//          focusProposer: .init()
//        )
//      }
//    )
//  }
// }
