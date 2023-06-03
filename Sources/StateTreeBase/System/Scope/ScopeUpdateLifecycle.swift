import TreeActor

/// State modelling for ``NodeScope``s during state updates.
///
/// State updates are resolved progressively and nodes step through
/// lifecycle events. As downstream changes happen in response to a change
/// other nodes are marked as dirty and must themselves step through a
/// change lifecycle.
enum ScopeUpdateLifecycle {

  // # Regular lifecycle stages

  // ## Stable cases.

  /// The scope is stable and does not need to be tracked.
  /// (Terminal 'readying' case.)
  case clean
  /// The scope has ended and does not need to be tracked.
  /// (Terminal 'finishing' case.)
  case finished

  // ## 'forwarding' cases resolved min-depth-first.

  /// The scope must start its lifecycle and then fire ``didStart`` events.
  case shouldStart
  /// The scope has started but must fire ``didStart`` events before transitioning to
  /// ``shouldHandleIntents``.
  case didStart

  /// The scope is dirty and must update.
  case shouldUpdate

  /// The scope must finally handle any pending applicable ``Intent`` before transitioning to
  /// ``shouldHandleIntents``.
  case shouldHandleIntents

  // ## 'finalizing' cases resolved max-depth-first.

  /// The scope must stop its sub-scopes and then continue stopping.
  case shouldPrepareStop
  /// The scope must fire ``willStop`` events and stop.
  case shouldNotifyStop
  /// The scope must stop.
  case shouldStop

  // MARK: Public

  @TreeActor
  public mutating func forward(
    scope: NodeScope<some Node>
  ) -> (() throws -> Bool)? {
    assert(requiresReadying)
    switch self {
    case .shouldStart:
      self = .shouldHandleIntents
      return {
        try scope.start()
        scope.didStart()
        return false
      }
    case .shouldUpdate:
      self = .shouldHandleIntents
      return {
        try scope.update()
        scope.didUpdate()
        return false
      }
    case .shouldHandleIntents:
      self = .clean
      return {
        scope.handleIntents()
        return true
      }
    default: return nil
    }
  }

  @TreeActor
  public mutating func finalize(
    scope: NodeScope<some Node>
  ) -> (() throws -> Bool)? {
    assert(requiresFinishing)
    switch self {
    case .shouldPrepareStop:
      self = .shouldNotifyStop
      return {
        try scope.stopSubtree()
        return false
      }
    case .shouldNotifyStop:
      self = .shouldStop
      return {
        scope.willStop()
        return false
      }
    case .shouldStop:
      self = .finished
      return {
        try scope.stop()
        return true
      }
    default: return nil
    }
  }

  // MARK: Internal

  var requiresReadying: Bool {
    switch self {
    case .shouldStart: return true
    case .shouldUpdate: return true
    case .shouldHandleIntents: return true
    default: return false
    }
  }

  var requiresFinishing: Bool {
    switch self {
    case .shouldStop: return true
    case .shouldPrepareStop: return true
    case .shouldNotifyStop: return true
    case .finished: return true
    default: return false
    }
  }

  var isStable: Bool {
    switch self {
    case .clean: return true
    case .finished: return true
    default: return false
    }
  }

  mutating func markRequiresUpdating() {
    switch self {
    case .clean:
      self = .shouldUpdate
    case .finished:
      self = .shouldUpdate
    case .shouldStart:
      return
    case .didStart:
      self = .shouldUpdate
    case .shouldUpdate:
      return
    case .shouldHandleIntents:
      self = .shouldUpdate
    case .shouldPrepareStop:
      return
    case .shouldNotifyStop:
      return
    case .shouldStop:
      return
    }
  }

  mutating func markRequiresStopping() {
    switch self {
    case .clean:
      self = .shouldPrepareStop
    case .finished:
      return
    case .shouldStart:
      self = .finished
    case .didStart:
      self = .shouldPrepareStop
    case .shouldUpdate:
      self = .shouldPrepareStop
    case .shouldHandleIntents:
      self = .shouldPrepareStop
    case .shouldPrepareStop:
      return
    case .shouldNotifyStop:
      return
    case .shouldStop:
      return
    }
  }

}
