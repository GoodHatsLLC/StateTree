// MARK: - URLQueryFragment

/// Keeps track if the string was percent encoded or not.
/// Prevents double encoding/double decoding
enum URLQueryFragment: ExpressibleByStringLiteral, Equatable {

  case urlEncoded(String)
  case urlDecoded(String)

  // MARK: Lifecycle

  init(stringLiteral: String) {
    self = .urlDecoded(stringLiteral)
  }

  // MARK: Internal

  var isEmpty: Bool {
    switch self {
    case .urlEncoded(let string):
      return string == ""
    case .urlDecoded(let string):
      return string == ""
    }
  }

  /// Do comparison and hashing using the decoded version as there are multiple ways something can
  /// be encoded.
  /// Certain characters that are not typically encoded could have been encoded making string
  /// comparisons between two encodings not work
  static func == (lhs: URLQueryFragment, rhs: URLQueryFragment) -> Bool {
    do {
      return try lhs.asURLDecoded() == rhs.asURLDecoded()
    } catch {
      return false
    }
  }

  /// Returns the URL Encoded version
  func asURLEncoded() throws -> String {
    switch self {
    case .urlEncoded(let encoded):
      return encoded
    case .urlDecoded(let decoded):
      return try decoded.urlEncoded()
    }
  }

  /// Returns the URL Decoded version
  func asURLDecoded() throws -> String {
    switch self {
    case .urlEncoded(let encoded):
      guard let decoded = encoded.removingPercentEncoding else {
        throw DecodingError.dataCorrupted(DecodingError.Context(
          codingPath: [],
          debugDescription: "Unable to remove percent encoding for \(encoded)"
        ))
      }
      return decoded
    case .urlDecoded(let decoded):
      return decoded
    }
  }

  func hash(into: inout Hasher) {
    do {
      try asURLDecoded().hash(into: &into)
    } catch { }
  }
}

// MARK: - URLEncodedFormData

/// Represents application/x-www-form-urlencoded encoded data.
internal struct URLEncodedFormData: ExpressibleByArrayLiteral, ExpressibleByStringLiteral,
  ExpressibleByDictionaryLiteral, Equatable
{

  // MARK: Lifecycle

  init(values: [URLQueryFragment] = [], children: [String: URLEncodedFormData] = [:]) {
    self.values = values
    self.children = children
  }

  init(stringLiteral: String) {
    self.values = [.urlDecoded(stringLiteral)]
    self.children = [:]
  }

  init(arrayLiteral: String...) {
    self.values = arrayLiteral.map { (s: String) -> URLQueryFragment in
      return .urlDecoded(s)
    }
    self.children = [:]
  }

  init(dictionaryLiteral: (String, URLEncodedFormData)...) {
    self.values = []
    self.children = Dictionary(uniqueKeysWithValues: dictionaryLiteral)
  }

  // MARK: Internal

  var values: [URLQueryFragment]
  var children: [String: URLEncodedFormData]
  let maxRecursionDepth = 100

  var hasOnlyValues: Bool {
    return children.isEmpty
  }

  var allChildKeysAreSequentialIntegers: Bool {
    for i in 0 ... children.count - 1 {
      if !children.keys.contains(String(i)) {
        return false
      }
    }
    return true
  }

  mutating func set(value: URLQueryFragment, forPath path: [String], recursionDepth: Int) throws {
    guard recursionDepth <= maxRecursionDepth else {
      throw URLEncodedFormError.reachedNestingLimit
    }
    guard let firstElement = path.first else {
      values.append(value)
      return
    }
    var child: URLEncodedFormData
    if let existingChild = children[firstElement] {
      child = existingChild
    } else {
      child = []
    }
    try child.set(value: value, forPath: Array(path[1...]), recursionDepth: recursionDepth + 1)
    children[firstElement] = child
  }
}
