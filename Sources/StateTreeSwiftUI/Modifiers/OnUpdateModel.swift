import Disposable
import Emitter
import Foundation
import Model
import SwiftUI

// MARK: - OnModelUpdate

@MainActor
public struct OnModelUpdate<M: Model>: ViewModifier {

  public init(model: M, updateType: StateUpdateType, action: @escaping @MainActor (M) -> Void) {
    self.action = action
    self.model = model
    self.updateType = updateType
  }

  public func body(content: Content) -> some View {
    content
      .task {
        action(model)
        let stream: AnyEmitter<UUID>
        switch updateType {
        case .all:
          stream = model.store.events.stateDidChange.erase()
        case .observed:
          stream = model.store.events.observedSubtreeDidChange.erase()
        }
        let seq = stream.values
        do {
          for try await _ in seq {
            action(model)
          }
        } catch {
          debugPrint("onUpdate(model:) failed", error)
        }
      }
  }

  let action: @MainActor (M) -> Void
  let model: M
  let updateType: StateUpdateType

}

// MARK: - StateUpdateType

public enum StateUpdateType {
  case all
  case observed
}

extension View {

  @MainActor
  public func onUpdate<M: Model>(
    model: M,
    updateType: StateUpdateType = .all,
    action: @escaping @MainActor (_ model: M) -> Void
  )
    -> some View
  {
    modifier(OnModelUpdate(model: model, updateType: updateType, action: action))
  }
}
