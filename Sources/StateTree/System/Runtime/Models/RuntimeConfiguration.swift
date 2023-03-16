import Behaviors

// MARK: - RuntimeConfiguration

public struct RuntimeConfiguration {

  // MARK: Lifecycle

  /// Configuration used for debugging and testing.
  /// - Parameters:
  ///   - internalError: The runtime alerting and logging configuration for internal StateTree
  /// errors.
  ///   - userError: The runtime alerting and logging configuration for user errors like circular
  /// dependencies.
  ///   - behaviorHandleTracking: Whether to retain or release handles to created ``Behavior``
  /// items. 'retain' is required for the ``TreeLifetime/behaviorResolutions`` testing hook.
  ///   - behaviorInterceptors: ``BehaviorInterceptor`` items to be swapped for ``Behavior`` items
  /// at runtime. Useful for testing.
  public init(
    userError: ErrorHandler = .assertion,
    behaviorManager: BehaviorManager = .init()
  ) {
    self.userError = userError
    self.behaviorManager = behaviorManager
  }

  // MARK: Public

  /// Developer or user visible notifications for error states
  public enum ErrorHandler {
    /// fatal errors which will cause production crashes
    case fatal
    /// assertions which will cause crashes in DEBUG only
    case assertion
    /// custom error handling
    case custom((Error) -> Void)
    /// no error handling
    case none
  }

  // MARK: Internal

  let userError: ErrorHandler
  let behaviorManager: BehaviorManager

}

extension RuntimeConfiguration.ErrorHandler {
  func handle(error: Error) {
    switch self {
    case .none:
      break
    case .fatal:
      fatalError(error.localizedDescription)
    case .assertion:
      assertionFailure(error.localizedDescription)
    case .custom(let handler):
      handler(error)
    }
  }
}
