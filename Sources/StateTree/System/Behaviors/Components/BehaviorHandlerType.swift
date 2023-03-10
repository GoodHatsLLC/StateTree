// MARK: - BehaviorHandlerType

public protocol BehaviorHandlerType<Event> {
  associatedtype Event: BehaviorEventType
  init(_ sender: @escaping @Sendable @TreeActor (Event) -> Void)
  var sender: @Sendable @TreeActor (Event) -> Void { get }
}

// MARK: - Behaviors.Handler

extension Behaviors {
  public struct Handler<Event: BehaviorEventType>: BehaviorHandlerType {
    public typealias Event = Event
    public init(_ sender: @escaping @Sendable @TreeActor (Event) -> Void) {
      self.sender = sender
    }

    public let sender: @Sendable @TreeActor (Event)
      -> Void

    @TreeActor
    public func send(event: Event) {
      sender(event)
    }
  }
}
