// MARK: - MetatypeWrapper

struct MetatypeWrapper {
  let metatype: Any.Type
}

// MARK: Equatable

extension MetatypeWrapper: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.metatype == rhs.metatype
  }
}

// MARK: Hashable

extension MetatypeWrapper: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(metatype))
  }
}
