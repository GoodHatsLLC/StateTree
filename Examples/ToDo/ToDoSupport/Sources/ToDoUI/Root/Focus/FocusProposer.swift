// import Combine
// import Foundation
// import ToDoDomain
//
// public struct FocusProposer {
//  public init() {}
//
//  public func send(proposal: AppFocus) {
//    focusSubject.send(proposal)
//  }
//
//  var navigationFocus: some Publisher<AppFocus.NavigationFocus?, Never> {
//    focusSubject
//      .map { appFocus in
//        switch appFocus {
//        case .unfocussed:
//          return nil
//        case .filters:
//          return .filters
//        case .todos:
//          return .todos
//        case .selected:
//          return .selected
//        }
//      }
//  }
//
//  var filterFocus: some Publisher<AppFocus.FilterFocus?, Never> {
//    focusSubject
//      .map { appFocus in
//        switch appFocus {
//        case .unfocussed:
//          return nil
//        case .filters(let filters):
//          return filters
//        case .todos:
//          return nil
//        case .selected:
//          return nil
//        }
//      }
//  }
//
//  var todosFocus: some Publisher<AppFocus.ToDoListFocus?, Never> {
//    focusSubject
//      .map { appFocus in
//        switch appFocus {
//        case .unfocussed:
//          return nil
//        case .filters:
//          return nil
//        case .todos(let focus):
//          return focus
//        case .selected:
//          return nil
//        }
//      }
//  }
//
//  var selectedFocus: some Publisher<AppFocus.SelectedFocus?, Never> {
//    focusSubject
//      .map { appFocus in
//        switch appFocus {
//        case .unfocussed:
//          return nil
//        case .filters:
//          return nil
//        case .todos:
//          return nil
//        case .selected(let selected):
//          return selected
//        }
//      }
//  }
//
//  private let focusSubject: PassthroughSubject<AppFocus, Never> = .init()
// }
