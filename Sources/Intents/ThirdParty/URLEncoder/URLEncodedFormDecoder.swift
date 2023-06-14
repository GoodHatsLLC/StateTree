import Foundation

// MARK: - URLEncodedFormDecoder

/// Decodes instances of `Decodable` types from `application/x-www-form-urlencoded` `Data`.
///
///     print(data) // "name=Vapor&age=3"
///     let user = try URLEncodedFormDecoder().decode(User.self, from: data)
///     print(user) // User
///
/// URL-encoded forms are commonly used by websites to send form data via POST requests. This
/// encoding is relatively
/// efficient for small amounts of data but must be percent-encoded.  `multipart/form-data` is more
/// efficient for sending
/// large data blobs like files.
///
/// See [Mozilla's](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST) docs for more
/// information about
/// url-encoded forms.
struct URLEncodedFormDecoder {

  // MARK: Lifecycle

  /// Create a new `URLEncodedFormDecoder`. Can be configured by using the global
  /// `ContentConfiguration` class
  ///
  ///     ContentConfiguration.global.use(urlDecoder: URLEncodedFormDecoder(bracketsAsArray: true,
  /// flagsAsBool: true, arraySeparator: nil))
  ///
  /// - parameters:
  ///     - configuration: Defines how decoding is done see `URLEncodedFormCodingConfig` for more
  /// information
  init(
    configuration: Configuration = .init()
  ) {
    self.parser = URLEncodedFormParser()
    self.configuration = configuration
  }

  // MARK: Internal

  /// Used to capture URLForm Coding Configuration used for decoding
  struct Configuration {

    // MARK: Lifecycle

    /// Creates a new `URLEncodedFormCodingConfiguration`.
    /// - parameters:
    ///     - boolFlags: Set to `true` allows you to parse `flag1&flag2` as boolean variables
    ///                  where object with variable `flag1` and `flag2` would decode to `true`
    ///                  or `false` depending on if the value was present or not. If this flag is
    /// set to
    ///                  true, it will always resolve for an optional `Bool`.
    ///     - arraySeparators: Uses these characters to decode arrays. If set to `,`, `arr=v1,v2`
    /// would
    ///                        populate a key named `arr` of type `Array` to be decoded as `["v1",
    /// "v2"]`
    ///     - dateDecodingStrategy: Date format used to decode a date. Date formats are tried in the
    /// order provided
    init(
      boolFlags: Bool = true,
      arraySeparators: [Character] = [",", "|"],
      dateDecodingStrategy: DateDecodingStrategy = .iso8601,
      userInfo: [CodingUserInfoKey: Any] = [:]
    ) {
      self.boolFlags = boolFlags
      self.arraySeparators = arraySeparators
      self.dateDecodingStrategy = dateDecodingStrategy
      self.userInfo = userInfo
    }

    // MARK: Internal

    /// Supported date formats
    enum DateDecodingStrategy {
      /// Seconds since 1 January 1970 00:00:00 UTC (Unix Timestamp)
      case secondsSince1970
      /// ISO 8601 formatted date
      case iso8601
      /// Using custom callback
      case custom((any Decoder) throws -> Date)
    }

    let boolFlags: Bool
    let arraySeparators: [Character]
    let dateDecodingStrategy: DateDecodingStrategy
    let userInfo: [CodingUserInfoKey: Any]

  }

  /// Decodes an instance of the supplied ``Decodable`` type from a ``String``.
  ///
  ///     print(data) // "name=Vapor&age=3"
  ///     let user = try URLEncodedFormDecoder().decode(User.self, from: data)
  ///     print(user) // User
  ///
  /// - Parameters:
  ///   - decodable: Generic ``Decodable`` type (``D``) to decode.
  ///   - string: String to decode a ``D`` from.
  ///   - userInfo: Overrides the default coder user info
  /// - returns: An instance of the `Decodable` type (``D``).
  /// - throws: Any error that may occur while attempting to decode the specified type.
  func decode<D>(
    _: D.Type,
    from string: String,
    userInfo: [CodingUserInfoKey: Any] = [:]
  ) throws
    -> D where D: Decodable
  {
    let parsedData = try parser.parse(string)
    let configuration: URLEncodedFormDecoder.Configuration
    if
      !userInfo
        .isEmpty
    { // Changing a coder's userInfo is a thread-unsafe mutation, operate on a copy
      configuration = .init(
        boolFlags: self.configuration.boolFlags,
        arraySeparators: self.configuration.arraySeparators,
        dateDecodingStrategy: self.configuration.dateDecodingStrategy,
        userInfo: self.configuration.userInfo.merging(userInfo) { $1 }
      )
    } else {
      configuration = self.configuration
    }
    let decoder = _Decoder(data: parsedData, codingPath: [], configuration: configuration)
    return try D(from: decoder)
  }

  // MARK: Private

  /// The underlying `URLEncodedFormEncodedParser`
  private let parser: URLEncodedFormParser

  private let configuration: Configuration

}

// MARK: - _Decoder

/// Private `Decoder`. See `URLEncodedFormDecoder` for decoder.
private struct _Decoder: Decoder {

  // MARK: Lifecycle

  /// Creates a new `_URLEncodedFormDecoder`.
  init(
    data: URLEncodedFormData,
    codingPath: [any CodingKey],
    configuration: URLEncodedFormDecoder.Configuration
  ) {
    self.data = data
    self.codingPath = codingPath
    self.configuration = configuration
  }

  // MARK: Internal

  struct KeyedContainer<Key>: KeyedDecodingContainerProtocol
    where Key: CodingKey
  {

    // MARK: Lifecycle

    init(
      data: URLEncodedFormData,
      codingPath: [any CodingKey],
      configuration: URLEncodedFormDecoder.Configuration
    ) {
      self.data = data
      self.codingPath = codingPath
      self.configuration = configuration
    }

    // MARK: Internal

    let data: URLEncodedFormData
    var codingPath: [any CodingKey]
    var configuration: URLEncodedFormDecoder.Configuration

    var allKeys: [Key] {
      return data.children.keys.compactMap { Key(stringValue: String($0)) }
    }

    func contains(_ key: Key) -> Bool {
      return data.children[key.stringValue] != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
      return data.children[key.stringValue] == nil
    }

    func decode<T>(_: T.Type, forKey key: Key) throws -> T where T: Decodable {
      // Check if we received a date. We need the decode with the appropriate format
      guard !(T.self is Date.Type) else {
        return try decodeDate(forKey: key) as! T
      }
      // If we are trying to decode a required array, we might not have decoded a child, but we
      // should still try to decode an empty array
      let child = data.children[key.stringValue] ?? []
      if let convertible = T.self as? any URLQueryFragmentConvertible.Type {
        guard let value = child.values.last else {
          if configuration.boolFlags {
            // If no values found see if we are decoding a boolean
            if let _ = T.self as? Bool.Type {
              return data.values.contains(.urlDecoded(key.stringValue)) as! T
            }
          }
          throw DecodingError.valueNotFound(T.self, at: codingPath + [key])
        }
        if let result = convertible.init(urlQueryFragmentValue: value) {
          return result as! T
        } else {
          throw DecodingError.typeMismatch(T.self, at: codingPath + [key])
        }
      } else {
        let decoder = _Decoder(
          data: child,
          codingPath: codingPath + [key],
          configuration: configuration
        )
        return try T(from: decoder)
      }
    }

    func nestedContainer<NestedKey>(
      keyedBy _: NestedKey.Type,
      forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey>
      where NestedKey: CodingKey
    {
      let child = data.children[key.stringValue] ?? []

      return KeyedDecodingContainer(KeyedContainer<NestedKey>(
        data: child,
        codingPath: codingPath + [key],
        configuration: configuration
      ))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
      let child = data.children[key.stringValue] ?? []

      return try UnkeyedContainer(
        data: child,
        codingPath: codingPath + [key],
        configuration: configuration
      )
    }

    func superDecoder() throws -> any Decoder {
      let child = data.children["super"] ?? []

      return _Decoder(
        data: child,
        codingPath: codingPath + [BasicCodingKey.key("super")],
        configuration: configuration
      )
    }

    func superDecoder(forKey key: Key) throws -> any Decoder {
      let child = data.children[key.stringValue] ?? []

      return _Decoder(
        data: child,
        codingPath: codingPath + [key],
        configuration: configuration
      )
    }

    // MARK: Private

    private func decodeDate(forKey key: Key) throws -> Date {
      // If we are trying to decode a required array, we might not have decoded a child, but we
      // should still try to decode an empty array
      let child = data.children[key.stringValue] ?? []
      return try configuration.decodeDate(from: child, codingPath: codingPath, forKey: key)
    }

  }

  struct UnkeyedContainer: UnkeyedDecodingContainer {

    // MARK: Lifecycle

    init(
      data: URLEncodedFormData,
      codingPath: [any CodingKey],
      configuration: URLEncodedFormDecoder.Configuration
    ) throws {
      self.data = data
      self.codingPath = codingPath
      self.configuration = configuration
      self.currentIndex = 0
      // Did we get an array with arr[0]=a&arr[1]=b indexing?
      // Cache this result
      self.allChildKeysAreNumbers = data.children.count > 0 && data
        .allChildKeysAreSequentialIntegers

      if allChildKeysAreNumbers {
        self.values = data.values
      } else {
        // No we got an array with arr[]=a&arr[]=b or arr=a&arr=b
        var values = data.values
        // empty brackets turn into empty strings!
        if let valuesInBracket = data.children[""] {
          values = values + valuesInBracket.values
        }

        // parse out any character separated array values
        self.values = try values.flatMap { value in
          try value.asURLEncoded()
            .split(
              omittingEmptySubsequences: false,
              whereSeparator: configuration.arraySeparators.contains
            )
            .map { (ss: Substring) in
              URLQueryFragment.urlEncoded(String(ss))
            }
        }
      }
    }

    // MARK: Internal

    let data: URLEncodedFormData
    let values: [URLQueryFragment]
    var codingPath: [any CodingKey]
    var configuration: URLEncodedFormDecoder.Configuration
    var allChildKeysAreNumbers: Bool

    var currentIndex: Int

    var count: Int? {
      // Did we get an array with arr[0]=a&arr[1]=b indexing?
      if allChildKeysAreNumbers {
        return data.children.count
      }
      // No we got an array with arr[]=a&arr[]=b or arr=a&arr=b
      return values.count
    }

    var isAtEnd: Bool {
      guard let count = count else {
        return true
      }
      return currentIndex >= count
    }

    func decodeNil() throws -> Bool {
      return false
    }

    mutating func decode<T>(_: T.Type) throws -> T where T: Decodable {
      defer { self.currentIndex += 1 }
      if allChildKeysAreNumbers {
        let childData = data.children[String(currentIndex)]!
        // We can force an unwrap because in the constructor
        // we checked data.allChildKeysAreNumbers
        let decoder = _Decoder(
          data: childData,
          codingPath: codingPath + [BasicCodingKey.index(currentIndex)],
          configuration: configuration
        )
        return try T(from: decoder)
      } else {
        let value = values[currentIndex]
        // Check if we received a date. We need the decode with the appropriate format.
        guard !(T.self is Date.Type) else {
          return try configuration.decodeDate(
            from: value,
            codingPath: codingPath,
            forKey: BasicCodingKey.index(currentIndex)
          ) as! T
        }

        if let convertible = T.self as? any URLQueryFragmentConvertible.Type {
          if let result = convertible.init(urlQueryFragmentValue: value) {
            return result as! T
          } else {
            throw DecodingError.typeMismatch(
              T.self,
              at: codingPath + [BasicCodingKey.index(currentIndex)]
            )
          }
        } else {
          // We need to pass in the value to be decoded
          let decoder = _Decoder(
            data: URLEncodedFormData(values: [value]),
            codingPath: codingPath + [BasicCodingKey.index(currentIndex)],
            configuration: configuration
          )
          return try T(from: decoder)
        }
      }
    }

    mutating func nestedContainer<NestedKey>(
      keyedBy _: NestedKey
        .Type
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
      throw DecodingError.typeMismatch(
        [String: any Decodable].self,
        at: codingPath + [BasicCodingKey.index(currentIndex)]
      )
    }

    mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
      throw DecodingError.typeMismatch(
        [any Decodable].self,
        at: codingPath + [BasicCodingKey.index(currentIndex)]
      )
    }

    mutating func superDecoder() throws -> any Decoder {
      defer { self.currentIndex += 1 }
      let data = allChildKeysAreNumbers
        ? data.children[currentIndex.description]!
        : .init(values: [values[currentIndex]])
      return _Decoder(
        data: data,
        codingPath: codingPath + [BasicCodingKey.index(currentIndex)],
        configuration: configuration
      )
    }
  }

  struct SingleValueContainer: SingleValueDecodingContainer {

    // MARK: Lifecycle

    init(
      data: URLEncodedFormData,
      codingPath: [any CodingKey],
      configuration: URLEncodedFormDecoder.Configuration
    ) {
      self.data = data
      self.codingPath = codingPath
      self.configuration = configuration
    }

    // MARK: Internal

    let data: URLEncodedFormData
    var codingPath: [any CodingKey]
    var configuration: URLEncodedFormDecoder.Configuration

    func decodeNil() -> Bool {
      data.values.isEmpty && data.children.isEmpty
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
      // Check if we received a date. We need the decode with the appropriate format.
      guard !(T.self is Date.Type) else {
        return try configuration.decodeDate(
          from: data,
          codingPath: codingPath,
          forKey: nil
        ) as! T
      }
      if let convertible = T.self as? any URLQueryFragmentConvertible.Type {
        guard let value = data.values.last else {
          throw DecodingError.valueNotFound(T.self, at: codingPath)
        }
        if let result = convertible.init(urlQueryFragmentValue: value) {
          return result as! T
        } else {
          throw DecodingError.typeMismatch(T.self, at: codingPath)
        }
      } else {
        let decoder = _Decoder(
          data: data,
          codingPath: codingPath,
          configuration: configuration
        )
        return try T(from: decoder)
      }
    }
  }

  var data: URLEncodedFormData
  var codingPath: [any CodingKey]
  var configuration: URLEncodedFormDecoder.Configuration

  /// See `Decoder`
  var userInfo: [CodingUserInfoKey: Any] { configuration.userInfo }

  func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key>
    where Key: CodingKey
  {
    return KeyedDecodingContainer(KeyedContainer<Key>(
      data: data,
      codingPath: codingPath,
      configuration: configuration
    ))
  }

  func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
    return try UnkeyedContainer(
      data: data,
      codingPath: codingPath,
      configuration: configuration
    )
  }

  func singleValueContainer() throws -> any SingleValueDecodingContainer {
    return SingleValueContainer(
      data: data,
      codingPath: codingPath,
      configuration: configuration
    )
  }

}

extension URLEncodedFormDecoder.Configuration {
  fileprivate func decodeDate(
    from data: URLEncodedFormData,
    codingPath: [any CodingKey],
    forKey key: (any CodingKey)?
  ) throws
    -> Date
  {
    let newCodingPath = codingPath + (key.map { [$0] } ?? [])
    switch dateDecodingStrategy {
    case .secondsSince1970:
      guard let value = data.values.last else {
        throw DecodingError.valueNotFound(Date.self, at: newCodingPath)
      }
      if let result = Date(urlQueryFragmentValue: value) {
        return result
      } else {
        throw DecodingError.typeMismatch(Date.self, at: newCodingPath)
      }
    case .iso8601:
      let decoder = _Decoder(data: data, codingPath: newCodingPath, configuration: self)
      let container = try decoder.singleValueContainer()
      if let date = ISO8601DateFormatter().date(from: try container.decode(String.self)) {
        return date
      } else {
        throw DecodingError.dataCorrupted(.init(
          codingPath: newCodingPath,
          debugDescription: "Unable to decode date. Expecting ISO8601 formatted date"
        ))
      }
    case .custom(let callback):
      let decoder = _Decoder(data: data, codingPath: newCodingPath, configuration: self)
      return try callback(decoder)
    }
  }

  fileprivate func decodeDate(
    from data: URLQueryFragment,
    codingPath: [any CodingKey],
    forKey key: (any CodingKey)?
  ) throws
    -> Date
  {
    try decodeDate(from: .init(values: [data]), codingPath: codingPath, forKey: key)
  }
}

extension DecodingError {
  fileprivate static func typeMismatch(
    _ type: Any.Type,
    at path: [any CodingKey]
  )
    -> DecodingError
  {
    let pathString = path.map(\.stringValue).joined(separator: ".")
    let context = DecodingError.Context(
      codingPath: path,
      debugDescription: "Data found at '\(pathString)' was not \(type)"
    )
    return Swift.DecodingError.typeMismatch(type, context)
  }

  fileprivate static func valueNotFound(
    _ type: Any.Type,
    at path: [any CodingKey]
  )
    -> DecodingError
  {
    let pathString = path.map(\.stringValue).joined(separator: ".")
    let context = DecodingError.Context(
      codingPath: path,
      debugDescription: "No \(type) was found at '\(pathString)'"
    )
    return Swift.DecodingError.valueNotFound(type, context)
  }
}
