// MARK: - WeakRef

struct WeakRef<T: AnyObject> {
  weak var ref: T?
}
