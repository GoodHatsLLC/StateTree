// MARK: - dynamiceMember

extension Projection {

  public subscript<Downstream>(
    dynamicMember keyPath: WritableKeyPath<Value, Downstream>
  ) -> Projection<Downstream> {
    map(keyPath)
  }

  public subscript<Downstream>(
    dynamicMember keyPath: WritableKeyPath<Value, Downstream>
  ) -> Projection<Downstream>? {
    map { value in
      value[keyPath: keyPath]
    } upwards: { upstream, downstream in
      var up = upstream
      if let downstream {
        up[keyPath: keyPath] = downstream
        upstream = up
      }
    }
    .compact()
  }

}
