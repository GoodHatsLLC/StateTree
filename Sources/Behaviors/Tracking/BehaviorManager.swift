import Emitter
import TreeActor

// MARK: - BehaviorManager

public actor BehaviorManager {

  // MARK: Lifecycle

  public init(
    trackingConfig: BehaviorTrackingConfig = .defaults,
    behaviorInterceptors: [BehaviorInterceptor] = []
  ) {
    self.trackingConfig = trackingConfig
    let index = behaviorInterceptors.indexed(by: \.id)
    self.behaviorInterceptors = index
    assert(
      behaviorInterceptors.count == index.count,
      "multiple interceptors can not be registered for the same behavior id."
    )
  }

  // MARK: Public

  /// Whether to track ``Behavior`` instances created during the runtime.
  /// ``BehaviorTrackingConfig/track`` is required to enable `await`ing
  /// ``TreeLifetime/behaviorResolutions`` in unit tests.
  public enum BehaviorTrackingConfig {
    /// Enable `await`ing ``TreeLifetime/behaviorResolutions`` in unit tests by retaining handles
    /// to created ``Behavior``s.
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

  public var behaviorResolutions: [Behaviors.Resolved] {
    get async {
      assert(
        trackingConfig.shouldTrack,
        "behaviorResolutions requires a RuntimeConfiguration with behaviorHandleTracking set to track"
      )
      if !trackingConfig.shouldTrack {
        assertionFailure()
      }
      var resolutions: [Behaviors.Resolved] = []
      let behaviors = trackedBehaviors
      for behavior in behaviors {
        let resolution = await behavior.value
        resolutions.append(resolution)
      }
      return resolutions
    }
  }

  @available(macOS 13.0, *)
  public nonisolated func behaviorResolutions(timeout: Duration) async throws
    -> [Behaviors.Resolved]
  {
    try await withThrowingTaskGroup(of: [Behaviors.Resolved].self) { group in
      group.addTask {
        await self.behaviorResolutions
      }
      group.addTask {
        try await Task.sleep(for: timeout)
        throw _Concurrency.CancellationError()
      }
      guard let first = try await group.next() else {
        throw _Concurrency.CancellationError()
      }
      group.cancelAll()
      return first
    }
  }

  // MARK: Internal

  nonisolated func intercept<B: BehaviorType>(
    behavior: inout B,
    input: B.Input
  ) {
    behaviorInterceptors[behavior.id]?.intercept(behavior: &behavior, input: input)
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

#if canImport(Foundation)
import Foundation
extension BehaviorManager {

  public nonisolated func behaviorResolutions(timeout: TimeInterval) async throws
    -> [Behaviors.Resolved]
  {
    try await withThrowingTaskGroup(of: [Behaviors.Resolved].self) { group in
      group.addTask {
        await self.behaviorResolutions
      }
      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        throw _Concurrency.CancellationError()
      }
      guard let first = try await group.next() else {
        throw _Concurrency.CancellationError()
      }
      group.cancelAll()
      return first
    }
  }
}

#endif
