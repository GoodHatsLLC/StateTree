@_spi(Implementation) import StateTreeBase

extension Projection {
  public var projectedValue: Projection<Value> {
    get {
      .init(self, initial: value)
    }
    nonmutating set { }
  }
}
