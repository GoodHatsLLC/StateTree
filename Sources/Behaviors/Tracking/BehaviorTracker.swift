import Emitter
import Foundation
import TreeActor
@_spi(Implementation) import Utilities

// MARK: - BehaviorTracker

public final class BehaviorTracker {

  // MARK: Lifecycle

  public init(
    tracking: Tracking = .defaults,
    behaviorInterceptors: [BehaviorInterceptor] = []
  ) {
    self.tracking = tracking
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
  public enum Tracking {

    public static var defaults: Tracking {
      #if DEBUG
        .indefinitely
      #else
        .untilComplete
      #endif
    }

    /// Track ``Behavior`` instances until they have completed or cancelled.
    ///
    /// This allows testing code to `await` all inflight behaviors before making
    /// assertions.
    case untilComplete

    /// Track ``Behavior`` instances indefinitely
    ///
    /// This allows testing code to inspect finished behavior resolutions.
    case indefinitely
  }

  public var behaviors: [Behaviors.Resolution] {
    trackedBehaviors.withLock { $0 }.map { $0 }
  }

  public var behaviorResolutions: [Behaviors.Resolved] {
    get async {
      var resolutions: [Behaviors.Resolved] = []
      let behaviors = trackedBehaviors.withLock { $0 }
      for behavior in behaviors {
        let resolution = await behavior.value
        resolutions.append(resolution)
      }
      return resolutions
    }
  }

  public func awaitReady(timeoutSeconds: Double? = nil) async throws {
    let behaviors = trackedBehaviors.withLock { $0 }
    if behaviors.isEmpty {
      runtimeWarning("there are no registered behaviors to await")
    }
    let action = {
      for behavior in behaviors {
        await behavior.awaitReady()
      }
    }
    if let timeoutSeconds {
      try await Async.timeout(seconds: timeoutSeconds) {
        await action()
      }.get()
    } else {
      await action()
    }
  }

  public func awaitFinished(timeoutSeconds: Double? = nil) async throws {
    let behaviors = trackedBehaviors.withLock { $0 }
    if behaviors.isEmpty {
      runtimeWarning("there are no registered behaviors to await")
    }
    let action = {
      for behavior in behaviors {
        _ = await behavior.value
      }
    }
    if let timeoutSeconds {
      try await Async.timeout(seconds: timeoutSeconds) {
        await action()
      }.get()
    } else {
      await action()
    }
  }

  // MARK: Internal

  nonisolated func intercept<B: BehaviorType>(
    behavior: inout B,
    input: B.Input
  ) {
    behaviorInterceptors[behavior.id]?.intercept(behavior: &behavior, input: input)
  }

  nonisolated func trackCreate(
    resolution: Behaviors
      .Resolution
  ) -> (started: @Sendable () -> Void, finished: @Sendable () -> Void) {
    trackedBehaviors
      .withLock { $0.insert(resolution) }

    return (
      started: { },
      finished: {
        if self.tracking == .untilComplete {
          self.trackedBehaviors
            .withLock { $0.remove(resolution) }
        }
      }
    )
  }

  // MARK: Private

  private let behaviorInterceptors: [BehaviorID: BehaviorInterceptor]
  private var trackedBehaviors: Locked<Set<Behaviors.Resolution>> = .init([])
  private let tracking: Tracking
}

extension BehaviorTracker {

  public nonisolated func behaviorResolutions(timeoutSeconds: Double? = nil) async throws
    -> [Behaviors.Resolved]
  {
    guard let timeoutSeconds
    else {
      return await behaviorResolutions
    }
    return try await Async.timeout(seconds: timeoutSeconds) {
      await self.behaviorResolutions
    }.get()
  }
}
