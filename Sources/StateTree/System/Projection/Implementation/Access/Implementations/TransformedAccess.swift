/// An ``Access`` which transforms another `Accessor`
struct TransformedAccess<Value>: Accessor {

  // MARK: Lifecycle

  init<Upstream>(
    upstream: some Accessor<Upstream>,
    map: some Transformer<Upstream, Value>
  ) {
    self.getterFunc = {
      map.downstream(
        from: upstream.value
      )
    }
    self.setterFunc = { newValue in
      upstream.value =
        map
          .upstream(
            from: newValue
          )
    }
    self.isValidFunc = {
      upstream
        .isValid()
        && map
        .isValid(
          given: upstream.value
        )
    }
    self.source = upstream.source
  }

  // MARK: Internal

  let source: ProjectionSource

  var value: Value {
    get { getterFunc() }
    nonmutating set { setterFunc(newValue) }
  }

  func isValid() -> Bool { isValidFunc() }
  func erase() -> AnyAccess<Value> { AnyAccess(self) }

  // MARK: Private

  private let getterFunc: () -> Value
  private let setterFunc: (Value) -> Void
  private let isValidFunc: () -> Bool

}
