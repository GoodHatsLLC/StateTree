extension Transform {
  /// A ``Transform.Passthrough`` forwards an upstream value as a downstream value
  /// without making any changes, using stored state, or triggering side effects.
  @TreeActor
  public struct Passthrough<Value>: Transformer {

    public init() { }

    public typealias Upstream = Value
    public typealias Downstream = Value

    public func downstream(from: Upstream) -> Downstream {
      from
    }

    public func upstream(from: Downstream) -> Upstream {
      from
    }

    public nonisolated func isValid(given _: Value) -> Bool {
      true
    }
  }
}
