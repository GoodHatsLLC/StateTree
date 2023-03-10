
// MARK: - BehaviorStateType

public protocol BehaviorStateType<Event>: Actor {
  associatedtype Event: BehaviorEventType
  init(resolution: Behaviors.Resolution)
  var id: BehaviorID { get }
  var resolution: Behaviors.Resolution { get }
  func update(handler: Behaviors.Handler<Event>, with event: Event)
}
