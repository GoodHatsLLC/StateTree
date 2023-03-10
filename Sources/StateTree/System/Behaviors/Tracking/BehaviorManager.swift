import Emitter

@TreeActor
public final class BehaviorManager {

  // MARK: Lifecycle

  public nonisolated init(
    trackingConfig: BehaviorTrackingConfig = .defaults,
    behaviorInterceptors: [BehaviorInterceptor] = []
  ) {
    self.trackingConfig = trackingConfig
    self.behaviorInterceptors = behaviorInterceptors.indexed(by: \.id)
    assert(
      behaviorInterceptors.count == self.behaviorInterceptors.count,
      "multiple interceptors can not be registered for the same behavior id."
    )
  }

  // MARK: Public

  /// Whether to track ``Behavior`` instances created during the runtime.
  /// ``BehaviorTrackingConfig/track`` is required to enable `await`ing
  /// ``TreeLifetime/resolvedBehaviors()`` in unit tests.
  public enum BehaviorTrackingConfig {
    /// Enable `await`ing ``TreeLifetime/resolvedBehaviors()`` in unit tests by retaining handles to
    /// created
    /// ``Behavior``s.
    case track
    /// Don't track ``Behavior`` handles.
    case none

    public static var defaults: BehaviorTrackingConfig {
      #if DEBUG
        .track
      #else
        .none
      #endif
    }

    var shouldTrack: Bool { self == .track }
  }

  public func resolvedBehaviors() async -> [Behaviors.Resolved] {
    assert(
      trackingConfig.shouldTrack,
      "resolvedBehaviors() requires a RuntimeConfiguration with behaviorHandleTracking set to .track"
    )
    if !trackingConfig.shouldTrack {
      runtimeWarning(
        "resolvedBehaviors() requires a RuntimeConfiguration with behaviorHandleTracking set to .track"
      )
    }
    var resolutions: [Behaviors.Resolved] = []
    let behaviors = trackedBehaviors
    for behavior in behaviors {
      let resolution = await behavior.value
      resolutions.append(resolution)
    }
    return resolutions
  }

  // MARK: Internal

  func intercept<B: BehaviorType>(
    type _: B.Type,
    id: BehaviorID,
    producer: inout B.Producer,
    input: B.Input
  ) {
    if
      let interceptor = behaviorInterceptors[id],
      let substituteProducer = interceptor.intercept(type: B.self, id: id, input: input)
    {
      producer = substituteProducer
    }
  }

  func track(resolution: Behaviors.Resolution) {
    if trackingConfig.shouldTrack {
      trackedBehaviors.append(resolution)
    }
  }

  // MARK: Private

  private let behaviorInterceptors: [BehaviorID: BehaviorInterceptor]
  private var trackedBehaviors: [Behaviors.Resolution] = []
  private let trackingConfig: BehaviorTrackingConfig
}
