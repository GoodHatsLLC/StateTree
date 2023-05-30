public struct WeakRef<T: AnyObject> {
  public init(_ ref: T?) {
    self.ref = ref
  }

  public weak var ref: T?
}
