import Foundation

// MARK: - MutRef

public final class MutRef<Thing> {

  public init(_ ref: Thing) {
    _ref = ref
  }

  private var _ref: Thing
  private let lock = NSLock()
  public var ref: Thing {
    set {
      lock.lock()
      _ref = newValue
      lock.unlock()
    }
    get {
      lock.lock()
      defer { lock.unlock() }
      return _ref

    }
  }
}

public typealias AnyMutRef = MutRef<AnyHashable>
