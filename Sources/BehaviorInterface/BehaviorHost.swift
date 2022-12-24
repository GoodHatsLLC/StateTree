import SourceLocation

// MARK: - _BehaviorHost

/// A type that can bind an ``BehaviorType`` to its lifecycle.
@MainActor
public protocol _BehaviorHost {
  func _produce<B: BehaviorType>(
    _: B,
    from: SourceLocation
  ) -> (() async throws -> B.Output)

  func _run<B: BehaviorType>(
    _: B,
    from: SourceLocation
  )
}
