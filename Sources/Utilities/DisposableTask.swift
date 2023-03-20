import Disposable

// MARK: - Disposables

public enum Disposables {
  public typealias SwiftTask = _Concurrency.Task
}

// MARK: Disposables.Task

extension Disposables {
  /// A wrapped for Swift's native `Task` which implements `Disposable`.
  ///
  /// Create a *running* wrapped `Task` with
  /// ``Disposables/Task/attached(priority:action:onDispose:)-7m9sh``
  /// or ``Disposables/Task/attached(priority:action:onDispose:)-7m9sh``.
  ///
  /// > Warning: This wrapper's behavior **does not** automatically trigger disposal when released
  /// (unless first type-erased to `AnyDisposable` with `erase()`).
  public struct Task<Success, Failure>: Disposable, Sendable where Success: Sendable,
    Failure: Error
  {

    // MARK: Lifecycle

    private init(
      mode: Mode,
      priority: TaskPriority? = nil,
      action: @escaping @Sendable () async -> Success,
      onDispose: @escaping @Sendable () -> Void
    ) where Failure == Never {
      let disposable = AnyDisposable(disposal: onDispose)
      self.disposable = disposable
      self.mode = mode
      switch mode {
      case .attached:
        self.task = SwiftTask(priority: priority) {
          await withTaskCancellationHandler(operation: action, onCancel: { disposable.dispose() })
        }
      case .detached:
        self.task = SwiftTask.detached(priority: priority) {
          await withTaskCancellationHandler(operation: action, onCancel: { disposable.dispose() })
        }
      }
    }

    private init(
      mode: Mode,
      priority: TaskPriority? = nil,
      action: @escaping @Sendable () async throws -> Success,
      onDispose: @escaping @Sendable () -> Void
    ) where Failure == any Error {
      let action = {
        try SwiftTask.checkCancellation()
        return try await action()
      }
      let disposable = AnyDisposable(disposal: onDispose)
      self.disposable = disposable
      self.mode = mode
      switch mode {
      case .attached:
        self.task = SwiftTask(priority: priority) {
          try await withTaskCancellationHandler(
            operation: action,
            onCancel: { disposable.dispose() }
          )
        }
      case .detached:
        self.task = SwiftTask.detached(priority: priority) {
          try await withTaskCancellationHandler(
            operation: action,
            onCancel: { disposable.dispose() }
          )
        }
      }
    }

    // MARK: Public

    /// Whether the underlying Swift `Task` runs as attached or detached.
    /// - `Attached` child tasks are cancelled if their parent is and automatically inherit their
    /// parent task's priority.
    /// - `Detached` tasks are parentless root tasks which don't inherit task priority.
    public enum Mode: Sendable {
      case attached
      case detached
    }

    /// Whether the underlying Swift `Task` runs as attached or detached.
    /// - `Attached` child tasks are cancelled if their parent is and automatically inherit their
    /// parent task's priority.
    /// - `Detached` tasks are parentless root tasks which don't inherit task priority.
    public let mode: Mode

    /// The result of the underlying `Task`
    public var result: Result<Success, Failure> {
      get async {
        await task.result
      }
    }

    /// Create a new attached `Task` wrapped to implement `Disposable`.
    /// The given `action` is immediately dispatched to begin running.
    ///
    /// - The given `onDispose` block is run once only.
    /// - The task will be cancelled and `onDispose` run if ``dispose()`` is called or if its parent
    /// `Task` is cancelled.
    /// - The task **not** be cancelled if this wrapping ``Disposables/Task`` is released — unless
    /// it is
    /// first type-erased to `AnyDisposable`.
    public static func attached(
      priority: TaskPriority? = nil,
      action: @escaping @Sendable () async -> Success,
      onDispose: @escaping @Sendable () -> Void
    ) -> Task<Success, Failure> where Failure == Never {
      .init(mode: .attached, priority: priority, action: action, onDispose: onDispose)
    }

    /// Create a new attached `Task` wrapped to implement `Disposable`.
    /// The given `action` is immediately dispatched to begin running.
    ///
    /// - The given `onDispose` block is run once only.
    /// - The task will be cancelled and `onDispose` run if ``dispose()`` is called or if its parent
    /// `Task` is cancelled.
    /// - The task **not** be cancelled if this wrapping ``Disposables/Task`` is released — unless
    /// it is
    /// first type-erased to `AnyDisposable`.
    public static func attached(
      priority: TaskPriority? = nil,
      action: @escaping @Sendable () async throws -> Success,
      onDispose: @escaping @Sendable () -> Void
    ) -> Task<Success, Failure> where Failure == any Error {
      .init(mode: .attached, priority: priority, action: action, onDispose: onDispose)
    }

    /// Create a new detached root `Task` wrapped to implement `Disposable`.
    /// The given `action` is immediately dispatched to begin running.
    ///
    /// - The task will be cancelled and `onDispose` run if ``dispose()`` is called (directly or
    /// indirectly— for example by a  `DisposableStage`).
    /// - The task will **not** be called if the creating task is cancelled — as it is a detached
    /// root.
    /// - The task **not** be cancelled if this wrapping ``Disposables/Task`` is released — unless
    /// it is
    /// first type-erased to `AnyDisposable`.
    public static func detached(
      priority: TaskPriority? = nil,
      action: @escaping @Sendable () async -> Success,
      onDispose: @escaping @Sendable () -> Void
    ) -> Task<Success, Failure> where Failure == Never {
      .init(mode: .detached, priority: priority, action: action, onDispose: onDispose)
    }

    /// Create a new detached root `Task` wrapped to implement `Disposable`.
    /// The given `action` is immediately dispatched to begin running.
    ///
    /// - The given `onDispose` block is run once only.
    /// - The task will be cancelled and `onDispose` run if ``dispose()`` is called (directly or
    /// indirectly— for example by a  `DisposableStage`).
    /// - The task will **not** be called if the creating task is cancelled — as it is a detached
    /// root.
    /// - The task **not** be cancelled if this wrapping ``Disposables/Task`` is released — unless
    /// it is
    /// first type-erased to `AnyDisposable`.
    public static func detached(
      priority: TaskPriority? = nil,
      action: @escaping @Sendable () async throws -> Success,
      onDispose: @escaping @Sendable () -> Void
    ) -> Task<Success, Failure> where Failure == any Error {
      .init(mode: .detached, priority: priority, action: action, onDispose: onDispose)
    }

    /// Cancel the underlying `Task`.
    public func dispose() {
      task.cancel()
      disposable.dispose()
    }

    // MARK: Private

    private let disposable: AnyDisposable
    private let task: SwiftTask<Success, Failure>

  }
}

extension Disposables.Task where Failure == Never {
  /// The value returned by the underlying `Task`
  public var value: Success {
    get async {
      await task.value
    }
  }
}

extension Disposables.Task where Failure == any Error {
  /// The value returned by the underlying `Task`, throwing if it ends in its `Failure` state.
  public var value: Success {
    get async throws {
      try await task.value
    }
  }
}
