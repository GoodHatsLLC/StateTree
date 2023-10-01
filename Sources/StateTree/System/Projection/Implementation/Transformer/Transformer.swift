// MARK: - Transformer

/// A `Transformer` can convert an upstream value to a downstream
/// value and vice versa.
///
/// The transformation represented is *not* necessarily a pure map.
/// * A transformer is 'upstream first', it primarily represents a mapping
/// from the upstream value to the downstream value.
/// * A transformer may only be valid when the upstream is in certain
/// states—and should be checked with ``isValid(given:)``.
/// * A transformer may contain stored state creating a 'memory' of
/// previous values as needed to fulfil its contract — as such transformers
/// should not be reused across different contexts.
///
/// > Warning: ``Transformer/value`` should not be called on an
/// invalid `Transformer`. The  property's behavior is undefined
/// when the `Transformer` is invalid and the program may fault.
protocol Transformer<Upstream, Downstream> {
  associatedtype Upstream
  associatedtype Downstream

  func downstream(from: Upstream) -> Downstream
  func upstream(from: Downstream) -> Upstream
  nonisolated func isValid(given: Upstream) -> Bool
}

// MARK: - Transform

enum Transform { }

extension Transformer {
  func erase() -> AnyTransformer<Upstream, Downstream> {
    AnyTransformer(
      downwards: { self.downstream(from: $0) },
      upwards: { self.upstream(from: $0) },
      isValid: { self.isValid(given: $0) }
    )
  }
}
