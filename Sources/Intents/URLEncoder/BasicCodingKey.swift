extension [CodingKey] {
  var dotPath: String { map(\.stringValue).joined(separator: ".") }
}

// MARK: - BasicCodingKey

/// A basic `CodingKey` implementation.
enum BasicCodingKey: CodingKey, Hashable {
  case key(String)
  case index(Int)

  // MARK: Lifecycle

  /// See `CodingKey`.
  init?(stringValue: String) {
    self = .key(stringValue)
  }

  /// See `CodingKey`.
  init?(intValue: Int) {
    self = .index(intValue)
  }

  init(_ codingKey: CodingKey) {
    if let intValue = codingKey.intValue {
      self = .index(intValue)
    } else {
      self = .key(codingKey.stringValue)
    }
  }

  init(_ codingKeyRepresentable: CodingKeyRepresentable) {
    self.init(codingKeyRepresentable.codingKey)
  }

  // MARK: Internal

  /// See `CodingKey`.
  var stringValue: String {
    switch self {
    case .index(let index): return index.description
    case .key(let key): return key
    }
  }

  /// See `CodingKey`.
  var intValue: Int? {
    switch self {
    case .index(let index): return index
    case .key(let key): return Int(key)
    }
  }
}

// MARK: CustomStringConvertible

extension BasicCodingKey: CustomStringConvertible {
  var description: String {
    switch self {
    case .index(let index):
      return index.description
    case .key(let key):
      return key.description
    }
  }
}

// MARK: CustomDebugStringConvertible

extension BasicCodingKey: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case .index(let index):
      return index.description
    case .key(let key):
      return key.debugDescription
    }
  }
}

// MARK: ExpressibleByStringLiteral

extension BasicCodingKey: ExpressibleByStringLiteral {
  init(stringLiteral: String) {
    self = .key(stringLiteral)
  }
}

// MARK: ExpressibleByIntegerLiteral

extension BasicCodingKey: ExpressibleByIntegerLiteral {
  init(integerLiteral: Int) {
    self = .index(integerLiteral)
  }
}
