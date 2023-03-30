import Disposable
import TreeActor

// MARK: - AsyncBehaviorType

public protocol AsyncBehaviorType: BehaviorType {
  func start(
    input: Input,
    handler: Handler,
    resolving: Behaviors.Resolution
  ) async
    -> AnyDisposable

  var subscriber: Behaviors.AsyncSubscriber<Input, Producer> { get }
}

extension AsyncBehaviorType {
  public func scoped(
    to scope: some BehaviorScoping,
    manager: BehaviorManager,
    input: Input
  ) -> ScopedBehavior<Self> {
    .init(behavior: self, scope: scope, manager: manager, input: input)
  }

  public func scoped(
    to scope: some BehaviorScoping,
    manager: BehaviorManager
  ) -> ScopedBehavior<Self> where Input == Void {
    .init(behavior: self, scope: scope, manager: manager, input: ())
  }

  public func scoped(
    manager: BehaviorManager,
    input: Input
  ) -> (scope: some Disposable, behavior: ScopedBehavior<Self>) {
    let stage = BehaviorStage()
    return (stage, .init(behavior: self, scope: stage, manager: manager, input: input))
  }

  public func scoped(manager: BehaviorManager)
    -> (scope: some Disposable, behavior: ScopedBehavior<Self>) where Input == Void
  {
    let stage = BehaviorStage()
    return (stage, .init(behavior: self, scope: stage, manager: manager, input: ()))
  }
}

// MARK: AsyncBehaviorType.Func

extension AsyncBehaviorType where Failure == Never {
  public typealias Func = (_ input: Input) async -> Output
}

// MARK: AsyncBehaviorType.Func

extension AsyncBehaviorType where Failure == Error {
  public typealias Func = (_ input: Input) async throws -> Output
}
