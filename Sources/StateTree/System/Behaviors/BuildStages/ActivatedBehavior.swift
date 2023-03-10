import Disposable
public struct ActivatedBehavior: Disposable, Hashable {

  // MARK: Lifecycle

  @TreeActor
  init<Behavior: BehaviorType>(
    behavior: Behavior,
    input: Behavior.Input,
    manager: BehaviorManager,
    handler: Behavior.Handler,
    resolution: Behaviors.Resolution? = nil
  ) {
    self.id = behavior.id
    var producer = behavior.producer
    manager
      .intercept(
        type: Behavior.self,
        id: behavior.id,
        producer: &producer,
        input: input
      )
    let stage = DisposableStage()
    let resolution = resolution ?? Behaviors.Resolution(id: id)
    assert(resolution.id == behavior.id)
    let state = Behavior.State(resolution: resolution)
    let handler: Behavior.Handler = .init { event in
      Task {
        await state.update(handler: handler, with: event)
      }
    }
    producer
      .start(
        input: input,
        handler: handler
      )
      .stage(on: stage)
    self.stage = stage
    self.resolution = resolution
    manager.track(resolution: resolution)
  }

  // MARK: Public

  public let id: BehaviorID
  public let resolution: Behaviors.Resolution

  public static func == (lhs: ActivatedBehavior, rhs: ActivatedBehavior) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public func dispose() {
    stage.dispose()
  }

  // MARK: Private

  private let stage: DisposableStage
}
