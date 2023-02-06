public typealias AnyTransformer<Upstream, Downstream> = Transform.Stateless<
  Upstream, Downstream
>

// MARK: - Transform.Stateless

extension Transform {
  /// A ``Transform.Stateless`` can directly and statelessly convert an upstream value
  /// to a downstream value and vice versa.
  public struct Stateless<Upstream, Downstream>: Transformer {

    // MARK: Lifecycle

    public nonisolated init(
      downwards: @escaping (_ upstream: Upstream) -> Downstream,
      upwards: @escaping (_ downstream: Downstream) -> Upstream,
      isValid: @escaping (_ given: Upstream) -> Bool
    ) {
      self.downwardsFunc = downwards
      self.upwardsFunc = upwards
      self.isValidFunc = isValid
    }

    // MARK: Public

    public func downstream(from: Upstream) -> Downstream {
      downwardsFunc(from)
    }

    public func upstream(from: Downstream) -> Upstream {
      upwardsFunc(from)
    }

    public func isValid(given upstream: Upstream) -> Bool {
      isValidFunc(upstream)
    }

    public func erase() -> AnyTransformer<Upstream, Downstream> {
      self
    }

    // MARK: Internal

    let downwardsFunc: (Upstream) -> Downstream
    let upwardsFunc: (Downstream) -> Upstream
    let isValidFunc: (Upstream) -> Bool

  }
}
