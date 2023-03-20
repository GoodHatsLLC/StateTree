import Disposable
import TreeActor
public struct ActivatedBehavior: Disposable, Hashable {

  // MARK: Lifecycle

  init<Behavior: BehaviorType>(
    behavior: Behavior,
    input: Behavior.Input,
    handler: Behavior.Handler,
    resolution: Behaviors.Resolution,
    scope: some BehaviorScoping
  ) async {
    self.id = behavior.id
    if scope.canOwn() {
      let disposable = await behavior
        .start(
          input: input,
          handler: handler,
          resolving: resolution
        )
      self.disposable = disposable
      self.resolution = resolution
      scope.own(self)
    } else {
      self.disposable = AnyDisposable { }
      await resolution.resolve(to: .cancelled)
      self.resolution = resolution
      await handler.cancel()
    }
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
    disposable.dispose()
  }

  // MARK: Private

  private let disposable: AnyDisposable
}
