import Disposable
import TreeActor

// MARK: - Behaviors

public enum Behaviors {
  public struct Cancellation: Error, Equatable { }
  public static let cancellation = Cancellation()
}

// MARK: - BehaviorType

public protocol BehaviorType {
  associatedtype Input
  associatedtype Producer: ProducerType
  associatedtype Value where Producer.Resolution.Value == Value, Handler.Value == Value
  associatedtype Resolution where Resolution == Producer.Resolution
  associatedtype Subscriber: SubscriberType where Subscriber.Input == Input,
    Handler.Producer == Producer
  associatedtype Handler: HandlerType where Handler.Producer == Producer
  init(_ id: BehaviorID, subscriber: Subscriber)
  var id: BehaviorID { get }
  var subscriber: Subscriber { get }
  func start(input: Input, handler: Handler, resolving: Behaviors.Resolution) async -> AnyDisposable
}

extension BehaviorType {
  public func scoped(to scope: some Scoping, manager: BehaviorManager) -> ScopedBehavior<Self> {
    .init(behavior: .init(behavior: self), scope: scope, manager: manager)
  }
}

// MARK: - Behavior

extension Behaviors {

  public enum Async {
    public enum Throwing { }
  }

  public enum Sync {
    public enum Throwing { }
  }
}
