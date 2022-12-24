import Foundation

// MARK: - MutRef

public struct ObjectRef<Object: AnyObject>: Hashable {
  nonisolated public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.identifier == rhs.identifier
  }

  nonisolated public func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }

  public init(_ ref: Object) {
    _ref = ref
  }

  private var _ref: Object
  private let lock = NSLock()
  public var identifier: ObjectIdentifier {
    ObjectIdentifier(ref)
  }
  public var ref: Object {
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

public typealias AnyObjectRef = ObjectRef<AnyObject>
