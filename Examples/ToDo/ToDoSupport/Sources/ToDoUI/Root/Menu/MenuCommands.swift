import Foundation
import SwiftUI
import ToDoDomain

public struct MenuCommands<DebugCommands: Commands>: Commands {
  public init(
    root: MenuViewModel,
    @CommandsBuilder debug: @escaping () -> DebugCommands
  ) {
    _menuModel = .init(wrappedValue: root)
    self.debug = debug()
  }

  public var body: some Commands {
    CommandGroup(replacing: .newItem) {
      Button {
        if let currentWindow = NSApp.keyWindow,
          let windowController = currentWindow
            .windowController
        {
          windowController.newWindowForTab(nil)
          if let newWindow = NSApp.keyWindow,
            currentWindow != newWindow
          {
            currentWindow
              .addTabbedWindow(newWindow, ordered: .above)
          }
        }
      } label: {
        Text("New Window Tab")
      }
      .keyboardShortcut("t", modifiers: [.command])
    }

    CommandGroup(after: .newItem) {
      Divider()
      Button {
        menuModel.createToDo()
      } label: {
        Text("New ToDo")
      }
      .keyboardShortcut("n", modifiers: [.command])
      Button {
        menuModel.toggleCompletion()
      } label: {
        Text("Toggle Completion")
      }
      .disabled(!menuModel.hasSelection)
      .keyboardShortcut(.return, modifiers: [.command])
      Button {
        menuModel.deleteSelection()
      } label: {
        Text("Delete Selected")
      }
      .disabled(!menuModel.hasSelection)
      .keyboardShortcut(.delete, modifiers: [.command])
    }
    CommandGroup(after: .textEditing) {
      Divider()
      Button {
        menuModel.focusFind()
      } label: {
        Text("Find ToDo")
      }
      .keyboardShortcut("f", modifiers: [.command])
      Button {
        menuModel.focusFilters()
      } label: {
        Text("Filter List")
      }
      .keyboardShortcut("f", modifiers: [.command, .shift])
      Button {
        menuModel.focusList()
      } label: {
        Text("List ToDos")
      }
      .keyboardShortcut("l", modifiers: [.command])
    }
    CommandGroup(after: .textEditing) {
      Divider()
      Button {
        menuModel.editTitle()
      } label: {
        Text("Edit Title")
      }
      .disabled(!menuModel.hasSelection)
      .keyboardShortcut("t", modifiers: [.command, .shift])
      Button {
        menuModel.editDate()
      } label: {
        Text("Edit Date")
      }
      .disabled(!menuModel.hasSelection)
      .keyboardShortcut("d", modifiers: [.command, .shift])
      Button {
        menuModel.editNote()
      } label: {
        Text("Edit Info")
      }
      .disabled(!menuModel.hasSelection)
      .keyboardShortcut("i", modifiers: [.command, .shift])
      Button {
        menuModel.addTag()
      } label: {
        Text("Add Tag")
      }
      .disabled(!menuModel.hasSelection)
      .keyboardShortcut("+", modifiers: [.command])
    }
    debug
  }

  @StateObject var menuModel: MenuViewModel
  @State var showDeletePrompt = false

  private let debug: DebugCommands

}
