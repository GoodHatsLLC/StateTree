import Foundation
public final class Ref<T>: @unchecked Sendable {

  // MARK: Lifecycle

  public init(value: T) {
    self._value = value
  }

  // MARK: Public

  public var value: T {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _value
    }
    _modify {
      lock.lock()
      defer { lock.unlock() }
      yield &_value
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      _value = newValue
    }
  }

  // MARK: Private

  private let lock = NSLock()
  private var _value: T
}
