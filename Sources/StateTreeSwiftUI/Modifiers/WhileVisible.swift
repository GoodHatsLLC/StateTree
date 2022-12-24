import Disposable
import Foundation
import SwiftUI

extension View {
  @MainActor
  public func whileVisible(
    behavior: @escaping () throws -> AnyDisposable
  )
    -> some View
  {
    modifier(
      DisposableVisibilityBinder(
        behaviorTrigger: behavior
      )
    )
  }

  @MainActor
  public func whileVisible(
    behavior: @escaping () throws -> some Disposable
  )
    -> some View
  {
    modifier(
      DisposableVisibilityBinder(
        behaviorTrigger: behavior
      )
    )
  }

  @MainActor
  public func whileVisible<Success: Sendable, Failure: Error>(
    behavior: @escaping () throws -> Task<Success, Failure>
  )
    -> some View
  {
    whileVisible {
      try behavior()
        .erase()
    }
  }
}

// MARK: - DisposableVisibilityBinder

@MainActor
public struct DisposableVisibilityBinder: ViewModifier {

  public init(behaviorTrigger: @escaping () throws -> some Disposable) {
    self.behaviorTrigger = { try behaviorTrigger().erase() }
  }

  let behaviorTrigger: () throws -> AnyDisposable

  @State var disposable: Disposable?

  public func body(content: Content) -> some View {
    content
      .onAppear {
        self.disposable = try? behaviorTrigger()
      }
      .onDisappear {
        self.disposable?.dispose()
        self.disposable = nil
      }
  }
}
