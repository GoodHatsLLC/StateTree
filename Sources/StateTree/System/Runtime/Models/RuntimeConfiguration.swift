import Behavior

// MARK: - RuntimeConfiguration

public struct RuntimeConfiguration {

  // MARK: Lifecycle

  /// Configuration used for debugging and testing.
  /// - Parameters:
  ///   - internalError: The runtime alerting and logging configuration for internal StateTree
  /// errors.
  ///   - behaviorHandleTracking: Whether to retain or release handles to created ``Behavior``
  /// items. 'retain' is required for the ``TreeLifetime/behaviorResolutions`` testing hook.
  ///   - behaviorInterceptors: ``BehaviorInterceptor`` items to be swapped for ``Behavior`` items
  /// at runtime. Useful for testing.
  public init(
    behaviorTracker: BehaviorTracker = .init()
  ) {
    self.behaviorTracker = behaviorTracker
  }

  // MARK: Internal

  let behaviorTracker: BehaviorTracker

}
