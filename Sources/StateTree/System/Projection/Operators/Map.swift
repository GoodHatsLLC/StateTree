// MARK: Map
extension Projection {

  // MARK: Public

  public func map<Downstream>(
    downwards: @escaping (
      _ upstream: Value
    ) -> Downstream,
    upwards: @escaping (
      _ varUpstream: inout Value,
      _ downstream: Downstream
    ) -> Void,
    isValid: @escaping (_ upstream: Value) -> Bool = { _ in true }
  ) -> Projection<Downstream> {
    .init(
      upstream: self,
      map: Transform.Stateless(
        downwards: downwards,
        upwards: { downstream in
          var upstream = value
          upwards(&upstream, downstream)
          return upstream
        },
        isValid: isValid
      )
    )
  }

  public func map<Downstream>(
    _ keyPath: WritableKeyPath<Value, Downstream>,
    isValid: @escaping (_ upstream: Value) -> Bool = { _ in true }
  ) -> Projection<Downstream> {
    .init(
      upstream: self,
      map: Transform.Stateless(
        downwards: { upstream in
          upstream[keyPath: keyPath]
        },
        upwards: { downstream in
          var value = value
          value[keyPath: keyPath] = downstream
          return value
        },
        isValid: isValid
      )
    )
  }

  // MARK: Internal

  func map<Downstream>(
    _ map: some Transformer<Value, Downstream>
  ) -> Projection<Downstream> {
    .init(
      upstream: self,
      map: map
    )
  }
}
