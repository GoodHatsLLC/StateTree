// MARK: - DependencyKey

public protocol DependencyKey: Hashable {
  associatedtype Value
  static var defaultValue: Value { get }
}

extension DependencyKey {
  public static var value: Value { defaultValue }
}

extension DependencyKey {
  static var hashable: AnyMetatypeWrapper {
    AnyMetatypeWrapper(metatype: self.self)
  }
}

// MARK: - AnyMetatypeWrapper

struct AnyMetatypeWrapper {
  let metatype: Any.Type
}

// MARK: Equatable

extension AnyMetatypeWrapper: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.metatype == rhs.metatype
  }
}

// MARK: Hashable

extension AnyMetatypeWrapper: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(metatype))
  }
}
