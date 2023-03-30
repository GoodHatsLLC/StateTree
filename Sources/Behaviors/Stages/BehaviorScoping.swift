import Disposable
import TreeActor
import Utilities

// MARK: - BehaviorScoping

public protocol BehaviorScoping {
  func own(_ disposable: some Disposable)
  func canOwn() -> Bool
}

// MARK: - BehaviorScopeHandler

struct BehaviorScopeHandler: BehaviorScoping {
  init(
    canHandle: @escaping () -> Bool = { true },
    handler: @escaping (_ disposable: any Disposable) -> Void
  ) {
    self.owner = handler
    self.checker = canHandle
  }

  private let owner: (any Disposable) -> Void
  private let checker: () -> Bool
  func own(_ disposable: some Disposable) {
    owner(disposable)
  }

  func canOwn() -> Bool {
    checker()
  }
}

// MARK: - BehaviorStage

public struct BehaviorStage: BehaviorScoping, Disposable {
  public init() { }
  private let stage = DisposableStage()
  public func own(_ disposable: some Disposable) {
    disposable.stage(on: stage)
  }

  public func reset() {
    stage.reset()
  }

  public func dispose() {
    stage.dispose()
  }

}

extension BehaviorScoping {
  public func canOwn() -> Bool {
    let disp = ReportingDisposable_HACK()
    own(disp)
    return !disp.isDisposed
  }
}

// MARK: - ReportingDisposable_HACK

private final class ReportingDisposable_HACK: Disposable {
  let lock = Locked(false)

  var isDisposed: Bool {
    lock.withLock { $0 }
  }

  func dispose() {
    lock.withLock { isDisposed in
      isDisposed = true
    }
  }
}

extension Behaviors {
  public enum Scope {
    public static var invalid: InvalidScope {
      runtimeWarning("The scope is not connected to a state tree and can not run a Behavior.")
      return .init()
    }
  }

  public struct InvalidScope: BehaviorScoping {
    public func own(_ disposable: some Disposable) {
      disposable.dispose()
    }

    public func canOwn() -> Bool {
      false
    }
  }
}
