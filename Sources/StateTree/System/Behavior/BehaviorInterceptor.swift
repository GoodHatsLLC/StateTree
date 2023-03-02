// MARK: - BehaviorInterceptor

/// `BehaviorInterceptor` mocks side effects for testing.
///
/// It allows for intercepting and replacing ``Behavior``s run in a ``Scope``.
///
/// Behavior interceptors are registered when starting the ``Tree``.
///
/// A ``Behavior`` is triggered via a ``Scope`` '`run`' function (e.g.
/// ``Scope/run(fileID:line:column:_:_:)-63046``).
///
/// The behavior's will be 'intercepted' and its ``Behavior/Action`` substituted for a registered
/// interceptor if:
///
/// 1. The interceptor's ``BehaviorInterceptor/id`` is equal to the triggered behavior's
/// ``Behavior/id``.
/// 2. The interceptor was created with an `action` parameter whose type exactly matches the
/// behavior's ``Behavior/Action``.
///
/// > Important: Only one interceptor can be registered per ``BehaviorID``.
public struct BehaviorInterceptor {

  // MARK: Lifecycle

  public init<BehaviorType: Behavior>(
    id: BehaviorID,
    type _: BehaviorType.Type,
    action: BehaviorType.Action
  ) {
    self.id = id
    self.handler = BehaviorInterceptionHandler<BehaviorType>(id: id, action: action)
  }

  // MARK: Public

  public let id: BehaviorID

  // MARK: Internal

  func intercept<Behavior: BehaviorType>(behavior _: Behavior, input _: Behavior.Input) -> Behavior
    .Action?
  {
    guard let handler = handler as? BehaviorInterceptionHandler<Behavior>
    else {
      return nil
    }
    return handler.action
  }

  // MARK: Private

  private let handler: any BehaviorInterceptionHandlerType

}

// MARK: - BehaviorInterceptionHandlerType

private protocol BehaviorInterceptionHandlerType<BehaviorType> {
  associatedtype BehaviorType: Behavior
  var id: BehaviorID { get }
  var action: BehaviorType.Action { get }
}

// MARK: - BehaviorInterceptionHandler

private struct BehaviorInterceptionHandler<BehaviorType: Behavior>: BehaviorInterceptionHandlerType {
  let id: BehaviorID
  let action: BehaviorType.Action
}
