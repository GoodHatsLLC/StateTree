import Disposable
import TreeActor
struct ActivatedBehavior: Disposable, Hashable {

  // MARK: Lifecycle

  init<Behavior: AsyncBehaviorType>(
    behavior: Behavior,
    input: Behavior.Input,
    handler: Behavior.Handler,
    resolution: Behaviors.Resolution
  ) async {
    self.id = behavior.id
    let disposable = await behavior
      .start(
        input: input,
        handler: handler,
        resolving: resolution
      )
    self.disposable = disposable
  }

  init<Behavior: SyncBehaviorType>(
    behavior: Behavior,
    input: Behavior.Input,
    handler: Behavior.Handler,
    resolution: Behaviors.Resolution
  ) where Behavior.Handler: HandlerType {
    self.id = behavior.id
    self.disposable = behavior
      .start(
        input: input,
        handler: handler,
        resolving: resolution
      )
  }

  init<Behavior: StreamBehaviorType>(
    behavior: Behavior,
    input: Behavior.Input,
    handler: Behavior.Handler,
    resolution: Behaviors.Resolution
  ) async {
    self.id = behavior.id
    let disposable = await behavior
      .start(
        input: input,
        handler: handler,
        resolving: resolution
      )
    self.disposable = disposable
  }

  // MARK: Internal

  let id: BehaviorID

  var isDisposed: Bool {
    disposable.isDisposed
  }

  static func == (lhs: ActivatedBehavior, rhs: ActivatedBehavior) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  func dispose() {
    disposable.dispose()
  }

  // MARK: Private

  private let disposable: AutoDisposable
}
