import Disposable
import TreeActor

// MARK: - SyncBehaviorType

public protocol SyncBehaviorType<Input, Output, Failure>: BehaviorType {
  var subscriber: Behaviors.SyncSubscriber<Input, Output, Failure> { get }
  func start(input: Input, handler: Handler, resolving: Behaviors.Resolution) -> AutoDisposable
}

// MARK: SyncBehaviorType.Func

extension SyncBehaviorType where Failure == Never {
  typealias Func = (_ input: Input) -> Output
}

// MARK: SyncBehaviorType.Func

extension SyncBehaviorType where Failure == Error {
  typealias Func = (_ input: Input) throws -> Output
}
