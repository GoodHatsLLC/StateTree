// MARK: - Async.Value

extension Async {

  /// A value `T` which will eventually be resolved for access.
  public actor Value<T: Sendable> {

    // MARK: Lifecycle

    /// Create a `Value<T>` that is not yet resolved and will
    /// cause ``value`` reads to suspend until it has been.
    public init() { }

    /// Create a `Value<T>` that is pre-resolved.
    public init(value: T) {
      self._value = value
    }

    // MARK: Public

    /// Access the potentially unresolved `T` instance, suspending indefinitely
    /// if it is not yet available.
    public var value: T {
      get async {
        if let _value {
          return _value
        } else {
          return await withCheckedContinuation { continuation in
            if let _value {
              // Actors allow re-entrance.
              // If `_value` was resolved while awaiting
              // `withCheckedContinuation` resume immediately.
              continuation.resume(with: .success(_value))
            } else {
              self.continuations.append(continuation)
            }
          }
        }
      }
    }

    /// Resolve to the passed `T` instance, unless already resolved.
    ///
    /// - Parameters:
    ///   - to: The value of `T` to resolve this instance to.
    ///   - action: An action to execute *if* resolving `T`, *after* resolving `T`, but *before*
    /// resuming any
    ///   suspended ``value`` accesses.
    ///
    /// > Important: `T` will be resolved and suspended accesses resumed even if a passed `action`
    /// closure causes this function to throw.
    public func resolve(to value: T) {
      guard _value == nil
      else {
        return
      }
      _value = value
      for continuation in continuations {
        continuation.resume(with: .success(value))
      }
    }

    /// Resolve to the passed `T` instance, unless already resolved.
    ///
    /// - Parameters:
    ///   - to: The value of `T` to resolve this instance to.
    ///   - action: An action to execute *if* resolving `T`, *after* resolving `T`, but *before*
    /// resuming any
    ///   suspended ``value`` accesses.
    ///
    /// > Important: `T` will be resolved and suspended accesses resumed even if a passed `action`
    /// closure causes this function to throw.
    public func resolve(to value: T, action: @escaping () throws -> Void = { }) rethrows {
      guard _value == nil
      else {
        return
      }
      _value = value
      defer {
        for continuation in continuations {
          continuation.resume(with: .success(value))
        }
      }
      try action()
    }

    /// Resolve to the passed `T` instance, resuming any suspended accesses and executing
    /// ``action`` (unless already resolved).
    ///
    /// - Parameters:
    ///   - to: The value of `T` to resolve this instance to.
    ///   - action: An action to execute *if* resolving `T`, *after* resolving `T`, but *before*
    /// resuming any
    ///   suspended ``value`` accesses.
    ///
    /// > Important: `T` will be resolved and suspended accesses resumed even if a passed `action`
    /// closure causes this function to throw.
    public func resolve(to value: T, action: @escaping () async throws -> Void) async rethrows {
      guard _value == nil
      else {
        return
      }
      _value = value
      defer {
        for continuation in continuations {
          continuation.resume(with: .success(value))
        }
      }
      try await action()
    }

    /// Test if the potentially-resolved `T` matches the passed filter, and if so execute
    /// the passed `action` closure.
    ///
    /// - Parameters:
    ///   - filter: The test for the conditional `action`.
    ///   - action: An action to execute *if* `filter` evaluates to `true` with the current `T`
    /// instance (or `nil` if unresolved).
    public func ifMatching(
      _ filter: (_ value: T?) -> Bool,
      action: @escaping () async throws -> Void
    ) async rethrows {
      if filter(_value) {
        try await action()
      }
    }

    // MARK: Private

    private var _value: T?
    private var continuations: [CheckedContinuation<T, Never>] = []
  }
}

extension Async.Value where T == Void {
  /// Resolve to the `Void` value resuming any suspended accesses and executing
  /// ``action`` (unless already resolved).
  ///
  /// - Parameters:
  ///   - action: An action to execute *if* resolving, *after* resolving, but *before* resuming any
  ///   suspended ``value`` accesses.
  ///
  /// > Important: The value will be resolved and suspended accesses resumed even if a passed
  /// `action`
  /// closure causes this function to throw.
  public func resolve(action: @escaping () async throws -> Void) async rethrows {
    try await resolve(to: (), action: action)
  }

  /// Resolve to the `Void` value resuming any suspended accesses (unless already resolved).
  public func resolve() {
    resolve(to: ())
  }
}
