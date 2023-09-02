import TreeActor

// MARK: CompactMap
extension Projection {

  public func compact<Downstream>() -> Projection<Downstream>? where Value == Downstream? {
    value.map { _ in
      .init(
        upstream: self,
        map: Transform.Stateless(
          downwards: { upstream in
            upstream!
          },
          upwards: { downstream in
            downstream
          },
          isValid: { $0 != nil }
        )
      )
    }
  }
}

extension Projection {
  public func compactMap<Downstream>(
    downwards: @escaping (Value) -> Downstream?,
    upwards: @escaping (Downstream) -> Value
  ) -> Projection<Downstream>? where Value == Downstream? {
    map(
      downwards: downwards,
      upwards: { upstream, downstream in
        if let downstream {
          upstream = upwards(downstream)
        }
      }
    )
    .compact()
  }

}

extension Projection {
  public init?(_ upstream: Projection<Value?>) {
    let upstream = upstream.compact()
    if let compacted = upstream {
      self = compacted
    } else {
      return nil
    }
  }
}
