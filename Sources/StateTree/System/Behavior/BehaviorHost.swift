import Emitter

public final class BehaviorHost {

  // MARK: Lifecycle

  public init(
    tracking: BehaviorTracking = .defaults,
    behaviorInterceptors: [BehaviorInterceptor] = []
  ) {
    self.tracking = tracking
    self.behaviorInterceptors = behaviorInterceptors.indexed(by: \.id)
    assert(
      behaviorInterceptors.count == self.behaviorInterceptors.count,
      "multiple interceptors can not be registered for the same behavior id."
    )
  }

  // MARK: Public

  /// Whether to track ``Behavior`` instances created during the runtime.
  /// ``BehaviorTracking/track`` is required to enable `await`ing
  /// ``TreeLifetime/resolvedBehaviors()`` in unit tests.
  public enum BehaviorTracking {
    /// Enable `await`ing ``TreeLifetime/resolvedBehaviors()`` in unit tests by retaining handles to
    /// created
    /// ``Behavior``s.
    case track
    /// Don't track ``Behavior`` handles.
    case none

    public static var defaults: BehaviorTracking {
      #if DEBUG
        .track
      #else
        .none
      #endif
    }
  }

  public func resolvedBehaviors() async -> [BehaviorResolution] {
    if tracking != .track {
      runtimeWarning(
        "resolvedBehaviors() requires a RuntimeConfiguration with behaviorHandleTracking set to .track"
      )
      assertionFailure(
        "resolvedBehaviors() requires a RuntimeConfiguration with behaviorHandleTracking set to .track"
      )
    }
    var resolutions: [BehaviorResolution] = []
    let behaviors = trackedBehaviors
    for behavior in behaviors {
      let resolution = await behavior.resolution()
      resolutions.append(resolution)
    }
    return resolutions
  }

  // MARK: Internal

  func offerTestHooks<Behavior: BehaviorType>(
    for behavior: Behavior,
    input: Behavior.Input
  )
    -> Behavior.Action?
  {
    if tracking == .track {
      trackedBehaviors.append(behavior.prepare(input))
    }
    let interceptor = behaviorInterceptors[behavior.id]
    let action = interceptor?.intercept(behavior: behavior, input: input)
    return action
  }

  // MARK: Private

  private let tracking: BehaviorTracking
  private let behaviorInterceptors: [BehaviorID: BehaviorInterceptor]
  private var trackedBehaviors: [PreparedBehavior] = []

}
