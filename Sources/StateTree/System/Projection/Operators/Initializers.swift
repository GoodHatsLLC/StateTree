import TreeActor

extension Projection {

  init(
    isValid: @escaping @autoclosure () -> Bool = true,
    getter: @escaping () -> Value,
    setter: @escaping (_ value: Value) -> Void
  ) {
    self.init(
      CapturedAccess(
        getter: getter,
        setter: setter,
        isValid: isValid
      ),
      initial: getter()
    )
  }

  @TreeActor
  init<Upstream>(
    upstream: some Accessor<Upstream>,
    map: some Transformer<Upstream, Value>
  ) {
    self.init(
      TransformedAccess(upstream: upstream, map: map),
      initial: map.downstream(from: upstream.value)
    )
  }
}
