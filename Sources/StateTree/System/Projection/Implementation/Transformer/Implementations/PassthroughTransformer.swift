import TreeActor

extension Transform {
  /// A ``Transform/Passthrough`` forwards an upstream value as a downstream value
  /// without making any changes, using stored state, or triggering side effects.
  struct Passthrough<Value>: Transformer {

    init() { }

    typealias Upstream = Value
    typealias Downstream = Value

    func downstream(from: Upstream) -> Downstream {
      from
    }

    func upstream(from: Downstream) -> Upstream {
      from
    }

    nonisolated func isValid(given _: Value) -> Bool {
      true
    }
  }
}
