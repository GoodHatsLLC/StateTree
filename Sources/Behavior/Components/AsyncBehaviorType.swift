import Disposable
import TreeActor

// MARK: - AsyncBehaviorType

public protocol AsyncBehaviorType<Input, Output, Failure>: BehaviorType {
  func start(
    input: Input,
    handler: Handler,
    resolving: Behaviors.Resolution
  ) async
    -> AutoDisposable

  var subscriber: Behaviors.AsyncSubscriber<Input, Output, Failure> { get }
}

// MARK: AsyncBehaviorType.Func

extension AsyncBehaviorType where Failure == Never {
  typealias Func = (_ input: Input) async -> Output
}

// MARK: AsyncBehaviorType.Func

extension AsyncBehaviorType where Failure == Error {
  typealias Func = (_ input: Input) async throws -> Output
}
