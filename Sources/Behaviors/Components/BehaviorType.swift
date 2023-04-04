import Disposable
import TreeActor

// MARK: - Behavior

public protocol Behavior<Input, Output, Failure> {
  associatedtype Input
  associatedtype Output
  associatedtype Failure: Error
  associatedtype Handler: HandlerType where Handler.Output == Output, Handler.Failure == Failure
  var id: BehaviorID { get }
  var switchType: BehaviorEmissionType<Input, Output, Failure> { get }
  mutating func setID(to: BehaviorID)
}

extension Behavior {

  public func erase() -> AnyBehavior<Input, Handler> {
    .init(self)
  }

  @discardableResult
  @TreeActor
  public func run(manager: BehaviorManager, scope: some BehaviorScoping, input: Input) -> Behaviors
    .Resolution
  {
    let (resolution, finalizer) = StartableBehavior(behavior: self)
      .start(manager: manager, input: input, scope: scope)
    Task {
      await finalizer?()
    }
    return resolution
  }

  @discardableResult
  @TreeActor
  public func run(
    manager: BehaviorManager,
    scope: some BehaviorScoping,
    input: Input,
    handler: Handler
  )
    -> Behaviors.Resolution
  {
    switch switchType {
    case .async(let asyncB):
      guard let h = handler as? Behaviors.SingleHandler<Asynchronous, Output, Failure>
      else {
        return .cancelled(id: id)
      }
      let (resolution, finalizer) = StartableBehavior(behavior: asyncB, handler: h)
        .start(manager: manager, input: input, scope: scope)
      Task {
        await finalizer?()
      }
      return resolution
    case .sync(let syncB):
      guard let h = handler as? Behaviors.SingleHandler<Synchronous, Output, Failure>
      else {
        return .cancelled(id: id)
      }
      let (resolution, finalizer) = StartableBehavior(behavior: syncB, handler: h)
        .start(manager: manager, input: input, scope: scope)
      Task {
        await finalizer?()
      }
      return resolution
    case .stream(let streamB):
      guard let h = handler as? Behaviors.StreamHandler<Asynchronous, Output, Failure>
      else {
        return .cancelled(id: id)
      }
      let (resolution, finalizer) = StartableBehavior(behavior: streamB, handler: h)
        .start(manager: manager, input: input, scope: scope)
      Task {
        await finalizer?()
      }
      return resolution
    }
  }
}

// MARK: - BehaviorType

public protocol BehaviorType<Input, Output, Failure>: Behavior {
  associatedtype Producer
  associatedtype Subscriber: SubscriberType where Subscriber.Input == Input
  init(
    _ id: BehaviorID,
    subscriber: Subscriber
  )
  var subscriber: Subscriber { get }
}

// MARK: - BehaviorEmissionType

public enum BehaviorEmissionType<Input, Output, Failure: Error> {
  case sync(Behaviors.SyncSingle<Input, Output, Failure>)
  case async(Behaviors.AsyncSingle<Input, Output, Failure>)
  case stream(Behaviors.Stream<Input, Output, Failure>)
}

// MARK: - AnyBehavior

public struct AnyBehavior<Input, Handler: HandlerType>: Behavior {
  public typealias Output = Handler.Output
  public typealias Failure = Handler.Failure

  init(_ behavior: some Behavior<Input, Output, Failure>) {
    var behavior = behavior
    self.id = behavior.id
    self.setIDFunc = {
      behavior.setID(to: $0)
    }
    self.switchTypeFunc = {
      behavior.switchType
    }
  }

  public let id: BehaviorID
  public var switchType: BehaviorEmissionType<Input, Output, Failure> {
    switchTypeFunc()
  }

  private let setIDFunc: (BehaviorID) -> Void
  private let switchTypeFunc: () -> BehaviorEmissionType<Input, Output, Failure>
  public func setID(to: BehaviorID) {
    setIDFunc(to)
  }
}
