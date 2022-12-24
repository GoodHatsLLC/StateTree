import Foundation

// MARK: - WeakRef

@MainActor
public struct WeakRef<Object: AnyObject>: Hashable {
  nonisolated public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.identifier == rhs.identifier
  }

  nonisolated public func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }

  public init(_ ref: Object) {
    self.ref = ref
    identifier = ObjectIdentifier(ref)
  }

  private let identifier: ObjectIdentifier
  public weak var ref: Object?

  public var isDeallocated: Bool {
    ref != nil
  }
}

public typealias AnyWeakRef = WeakRef<AnyObject>
