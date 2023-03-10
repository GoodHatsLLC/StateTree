// MARK: - BehaviorInterceptor

public struct BehaviorInterceptor {

  // MARK: Lifecycle

  public init<B: BehaviorType>(
    id: BehaviorID,
    type _: B.Type,
    producer: B.Producer,
    filter: @escaping @Sendable (_ input: B.Input) -> Bool = { _ in true }
  ) {
    self.id = id
    self.handler = BehaviorInterceptionHandler<B>(id: id, filter: filter, producer: producer)
  }

  // MARK: Public

  public let id: BehaviorID

  // MARK: Internal

  func intercept<B: BehaviorType>(type _: B.Type, id _: BehaviorID, input: B.Input) -> B
    .Producer?
  {
    guard
      let handler = handler as? BehaviorInterceptionHandler<B>,
      handler.filter(input)
    else {
      return nil
    }
    return handler.producer
  }

  // MARK: Private

  private let handler: any BehaviorInterceptionHandlerType

}

// MARK: - BehaviorInterceptionHandlerType

private protocol BehaviorInterceptionHandlerType<B> {
  associatedtype B: BehaviorType
  var id: BehaviorID { get }
  var filter: @Sendable (B.Input) -> Bool { get }
  var producer: B.Producer { get }
}

// MARK: - BehaviorInterceptionHandler

public struct BehaviorInterceptionHandler<B: BehaviorType>: BehaviorInterceptionHandlerType {
  let id: BehaviorID
  let filter: @Sendable (B.Input) -> Bool
  let producer: B.Producer
}
