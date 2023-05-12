extension Projection {

  public nonisolated static func stored<V>(_ value: V) -> Projection<V> {
    .init(StoredAccess(value), initial: value)
  }

  public nonisolated static func constant<V>(_ value: V) -> Projection<V> {
    .init(ConstantAccess(value), initial: value)
  }

  public nonisolated static func captured<V>(
    getter: @escaping () -> V,
    setter: @escaping (V) -> Void
  ) -> Projection<V> {
    .init(
      CapturedAccess(
        getter: getter,
        setter: setter
      ),
      initial: getter()
    )
  }

}
