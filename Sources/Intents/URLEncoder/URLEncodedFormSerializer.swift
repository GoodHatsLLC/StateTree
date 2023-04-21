import struct Foundation.CharacterSet

// MARK: - URLEncodedFormSerializer

/// Source: https://github.com/vapor/vapor/tree/f4b00a5350238fe896d865d96d64f12fcbbeda95/Sources/Vapor/URLEncodedForm
/// License: https://github.com/vapor/vapor/blob/main/LICENSE
struct URLEncodedFormSerializer {

  // MARK: Lifecycle

  /// Create a new form-urlencoded data parser.
  init(splitVariablesOn: Character = "&", splitKeyValueOn: Character = "=") {
    self.splitVariablesOn = splitVariablesOn
    self.splitKeyValueOn = splitKeyValueOn
  }

  // MARK: Internal

  struct _CodingKey: CodingKey {
    var stringValue: String

    init(stringValue: String) {
      self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
      self.intValue = intValue
      self.stringValue = intValue.description
    }
  }

  let splitVariablesOn: Character
  let splitKeyValueOn: Character

  func serialize(_ data: URLEncodedFormData, codingPath: [CodingKey] = []) throws -> String {
    var entries: [String] = []
    let key = try codingPath.toURLEncodedKey()
    for value in data.values {
      if codingPath.isEmpty {
        try entries.append(value.asURLEncoded())
      } else {
        try entries.append(key + String(splitKeyValueOn) + value.asURLEncoded())
      }
    }
    for (key, child) in data.children {
      entries
        .append(try serialize(
          child,
          codingPath: codingPath + [_CodingKey(stringValue: key) as CodingKey]
        ))
    }
    return entries.joined(separator: String(splitVariablesOn))
  }
}

extension [CodingKey] {
  func toURLEncodedKey() throws -> String {
    if count < 1 {
      return ""
    }
    return try self[0].stringValue.urlEncoded(codingPath: self) + self[1...]
      .map { (key: CodingKey) -> String in
        return try "[" + key.stringValue.urlEncoded(codingPath: self) + "]"
      }.joined()
  }
}

// MARK: Utilties

extension String {
  /// Prepares a `String` for inclusion in form-urlencoded data.
  func urlEncoded(codingPath: [CodingKey] = []) throws -> String {
    guard
      let result = self.addingPercentEncoding(
        withAllowedCharacters: URLEncoding.allowedCharacters
      )
    else {
      throw EncodingError.invalidValue(self, EncodingError.Context(
        codingPath: codingPath,
        debugDescription: "Unable to add percent encoding to \(self)"
      ))
    }
    return result
  }
}

// MARK: - URLEncoding

enum URLEncoding {
  /// Characters allowed in form-urlencoded data.
  static let allowedCharacters: CharacterSet = {
    var allowed = CharacterSet.urlQueryAllowed
    // these symbols are reserved for url-encoded form
    // NOTE: "/" character added for intents use.
    allowed.remove(charactersIn: "?&=[];+/")
    return allowed
  }()

  struct EncodingError: Error { }
}
