typealias AnyTransformer<Upstream, Downstream> = Transform.Stateless<
  Upstream, Downstream
>

// MARK: - Transform.Stateless

extension Transform {
  /// A ``Transform/Stateless`` can directly and statelessly convert an upstream value
  /// to a downstream value and vice versa.
  struct Stateless<Upstream, Downstream>: Transformer {

    // MARK: Lifecycle

    nonisolated init(
      downwards: @escaping (_ upstream: Upstream) -> Downstream,
      upwards: @escaping (_ downstream: Downstream) -> Upstream,
      isValid: @escaping (_ given: Upstream) -> Bool
    ) {
      self.downwardsFunc = downwards
      self.upwardsFunc = upwards
      self.isValidFunc = isValid
    }

    // MARK: Internal

    let downwardsFunc: (Upstream) -> Downstream
    let upwardsFunc: (Downstream) -> Upstream
    let isValidFunc: (Upstream) -> Bool

    func downstream(from: Upstream) -> Downstream {
      downwardsFunc(from)
    }

    func upstream(from: Downstream) -> Upstream {
      upwardsFunc(from)
    }

    func isValid(given upstream: Upstream) -> Bool {
      isValidFunc(upstream)
    }

    func erase() -> AnyTransformer<Upstream, Downstream> {
      self
    }

  }
}
