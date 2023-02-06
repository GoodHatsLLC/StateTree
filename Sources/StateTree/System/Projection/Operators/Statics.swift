extension Projection {

  public static func stored<V>(_ value: V) -> Projection<V> {
    .init(StoredAccess(value))
  }

  public static func constant<V>(_ value: V) -> Projection<V> {
    .init(ConstantAccess(value))
  }

  public static func captured<V>(
    getter: @escaping () -> V,
    setter: @escaping (V) -> Void
  ) -> Projection<V> {
    .init(
      CapturedAccess(
        getter: getter,
        setter: setter
      )
    )
  }

}
