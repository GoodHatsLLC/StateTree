import StateTreeSwiftUI
import SwiftUI
import ToDoDomain

public struct FilterListView: View {

  public var body: some View {
    Section {
      List(ToDoMetadata.allCases, selection: $viewModel.filterType) { type in
        NavigationLink(type.text, value: type)
          .focused($focus, equals: type)
      }
    }
    .onReceive(viewModel.focusProposer.filterFocus) { filter in
      // The filter is not just focus, it is used for
      // selection. Selection is a core state. Bridge
      // to it.

      switch filter {
      case .none:
        focus = nil
      case .any:
        focus = nil
      case .specific(let meta):
        viewModel.filterType = meta
        focus = meta
      }
    }
  }

  @FocusState var focus: ToDoMetadata?
  @ObservedObject var viewModel: FilterListViewModel

}
