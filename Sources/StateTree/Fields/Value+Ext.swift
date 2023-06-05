@_spi(Implementation) import StateTreeBase

extension Value {
  public var projectedValue: Projection<WrappedValue> {
    .init(
      self,
      initial: initial
    )
  }
}
