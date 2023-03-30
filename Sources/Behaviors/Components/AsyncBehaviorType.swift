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

  @TreeActor
  public func scoped(
    to scope: some BehaviorScoping,
    manager: BehaviorManager
  ) -> ScopedBehavior<Self> where Input == Void {
    .init(behavior: self, scope: scope, manager: manager, input: ())
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
