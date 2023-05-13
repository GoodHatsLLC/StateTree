// MARK: - BehaviorInterceptor

public struct BehaviorInterceptor {

  // MARK: Lifecycle

  public init<B: BehaviorType>(
    id: BehaviorID,
    type _: B.Type,
    subscriber: B.Subscriber,
    filter: @escaping @Sendable (_ input: B.Input) -> Bool = { _ in true }
  ) {
    self.id = id
    self.handler = BehaviorInterceptionHandler<B>(id: id, filter: filter, subscriber: subscriber)
  }

  public init<B: BehaviorType>(
    id: BehaviorID,
    replacement: B,
    filter: @escaping @Sendable (_ input: B.Input) -> Bool = { _ in true }
  ) {
    self.id = id
    self
      .handler = BehaviorInterceptionHandler<B>(
        id: id,
        filter: filter,
        subscriber: replacement.subscriber
      )
  }

  // MARK: Internal

  let id: BehaviorID

  func intercept<B: BehaviorType>(behavior: inout B, input: B.Input) {
    guard
      let handler = handler as? BehaviorInterceptionHandler<B>,
      handler.filter(input)
    else {
      return
    }
    let modifiedBehavior: B = .init(behavior.id, subscriber: handler.subscriber)
    behavior = modifiedBehavior
  }

  // MARK: Private

  private let handler: any BehaviorInterceptionHandlerType

}

// MARK: - BehaviorInterceptionHandlerType

private protocol BehaviorInterceptionHandlerType<B> {
  associatedtype B: BehaviorType
  var id: BehaviorID { get }
  var filter: @Sendable (B.Input) -> Bool { get }
  var subscriber: B.Subscriber { get }
}

// MARK: - BehaviorInterceptionHandler

struct BehaviorInterceptionHandler<B: BehaviorType>: BehaviorInterceptionHandlerType {
  let id: BehaviorID
  let filter: @Sendable (B.Input) -> Bool
  let subscriber: B.Subscriber
}
