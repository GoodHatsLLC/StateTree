import Foundation

// MARK: - URLEncodedFormEncoder

/// Encodes `Encodable` instances to `application/x-www-form-urlencoded` data.
///
///     print(user) /// User
///     let data = try URLEncodedFormEncoder().encode(user)
///     print(data) /// Data
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
/// NOTE: This implementation of the encoder does not support encoding booleans to "flags".
struct URLEncodedFormEncoder {

  // MARK: Lifecycle

  /// Create a new `URLEncodedFormEncoder`.
  ///
  ///      ContentConfiguration.global.use(urlEncoder: URLEncodedFormEncoder())
  ///
  /// - Parameters:
  ///  - configuration: Defines how encoding is done; see ``URLEncodedFormEncoder/Configuration``
  /// for more information
  init(configuration: Configuration = .init()) {
    self.configuration = configuration
  }

  // MARK: Internal

  /// Used to capture URLForm Coding Configuration used for encoding.
  struct Configuration {

    // MARK: Lifecycle

    /// Creates a new `Configuration`.
    ///
    ///  - parameters:
    ///     - arrayEncoding: Specified array encoding. Defaults to `.bracket`.
    ///     - dateFormat: Format to encode date format too. Defaults to `secondsSince1970`
    init(
      arrayEncoding: ArrayEncoding = .bracket,
      dateEncodingStrategy: DateEncodingStrategy = .iso8601,
      userInfo: [CodingUserInfoKey: Any] = [:]
    ) {
      self.arrayEncoding = arrayEncoding
      self.dateEncodingStrategy = dateEncodingStrategy
      self.userInfo = userInfo
    }

    // MARK: Internal

    /// Supported array encodings.
    enum ArrayEncoding {
      /// Arrays are serialized as separate values with bracket suffixed keys.
      /// For example, `foo = [1,2,3]` would be serialized as `foo[]=1&foo[]=2&foo[]=3`.
      case bracket
      /// Arrays are serialized as a single value with character-separated items.
      /// For example, `foo = [1,2,3]` would be serialized as `foo=1,2,3`.
      case separator(Character)
      /// Arrays are serialized as separate values.
      /// For example, `foo = [1,2,3]` would be serialized as `foo=1&foo=2&foo=3`.
      case values
    }

    /// Supported date formats
    enum DateEncodingStrategy {
      /// Seconds since 1 January 1970 00:00:00 UTC (Unix Timestamp)
      case secondsSince1970
      /// ISO 8601 formatted date
      case iso8601
      /// Using custom callback
      case custom((Date, any Encoder) throws -> Void)
    }

    /// Specified array encoding.
    var arrayEncoding: ArrayEncoding
    var dateEncodingStrategy: DateEncodingStrategy
    var userInfo: [CodingUserInfoKey: Any]

  }

  /// Encodes the supplied ``Encodable`` object to ``String``.
  ///
  ///     print(user) // User
  ///     let data = try URLEncodedFormEncoder().encode(user)
  ///     print(data) // "name=Vapor&age=3"
  ///
  /// - Parameters:
  ///   - encodable: Generic ``Encodable`` object (``E``) to encode.
  ///   - userInfo: Overrides the default coder user info.
  /// - Returns: Encoded ``String``
  /// - Throws: Any error that may occur while attempting to encode the specified type.
  func encode(
    _ encodable: some Encodable,
    userInfo: [CodingUserInfoKey: Any] = [:]
  ) throws
    -> String
  {
    var configuration =
      configuration // Changing a coder's userInfo is a thread-unsafe mutation, operate on a copy
    if !userInfo.isEmpty {
      configuration.userInfo.merge(userInfo) { $1 }
    }
    let encoder = _Encoder(codingPath: [], configuration: configuration)
    try encodable.encode(to: encoder)
    let serializer = URLEncodedFormSerializer()
    return try serializer.serialize(encoder.getData())
  }

  // MARK: Private

  private let configuration: Configuration

}

// MARK: - _Container

private protocol _Container {
  func getData() throws -> URLEncodedFormData
}

// MARK: - _Encoder

private class _Encoder: Encoder, _Container {

  // MARK: Lifecycle

  init(codingPath: [any CodingKey], configuration: URLEncodedFormEncoder.Configuration) {
    self.codingPath = codingPath
    self.configuration = configuration
  }

  // MARK: Internal

  var codingPath: [any CodingKey]

  var userInfo: [CodingUserInfoKey: Any] { configuration.userInfo }

  func getData() throws -> URLEncodedFormData { try container?.getData() ?? [] }

  func container<Key: CodingKey>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
    let container = KeyedContainer<Key>(codingPath: codingPath, configuration: configuration)
    self.container = container
    return .init(container)
  }

  func unkeyedContainer() -> any UnkeyedEncodingContainer {
    let container = UnkeyedContainer(codingPath: codingPath, configuration: configuration)
    self.container = container
    return container
  }

  func singleValueContainer() -> any SingleValueEncodingContainer {
    let container = SingleValueContainer(codingPath: codingPath, configuration: configuration)
    self.container = container
    return container
  }

  // MARK: Private

  private final class KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol, _Container {

    // MARK: Lifecycle

    init(
      codingPath: [any CodingKey],
      configuration: URLEncodedFormEncoder.Configuration
    ) {
      self.codingPath = codingPath
      self.configuration = configuration
    }

    // MARK: Internal

    var codingPath: [any CodingKey]
    var internalData: URLEncodedFormData = []
    var childContainers: [String: any _Container] = [:]

    func getData() throws -> URLEncodedFormData {
      var result = internalData
      for (key, childContainer) in childContainers {
        result.children[key] = try childContainer.getData()
      }
      return result
    }

    /// See `KeyedEncodingContainerProtocol`
    func encodeNil(forKey _: Key) throws {
      // skip
    }

    /// See `KeyedEncodingContainerProtocol`
    func encode(_ value: some Encodable, forKey key: Key) throws {
      if let date = value as? Date {
        internalData.children[key.stringValue] = try configuration
          .encodeDate(date, codingPath: codingPath, forKey: key)
      } else if let convertible = value as? any URLQueryFragmentConvertible {
        internalData
          .children[key.stringValue] =
          URLEncodedFormData(values: [convertible.urlQueryFragmentValue])
      } else {
        let encoder = _Encoder(codingPath: codingPath + [key], configuration: configuration)
        try value.encode(to: encoder)
        internalData.children[key.stringValue] = try encoder.getData()
      }
    }

    /// See `KeyedEncodingContainerProtocol`
    func nestedContainer<NestedKey: CodingKey>(
      keyedBy _: NestedKey.Type,
      forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
      let container = KeyedContainer<NestedKey>(
        codingPath: codingPath + [key],
        configuration: configuration
      )
      childContainers[key.stringValue] = container
      return .init(container)
    }

    /// See `KeyedEncodingContainerProtocol`
    func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
      let container = UnkeyedContainer(
        codingPath: codingPath + [key],
        configuration: configuration
      )
      childContainers[key.stringValue] = container
      return container
    }

    /// See `KeyedEncodingContainerProtocol`
    func superEncoder() -> any Encoder {
      let encoder = _Encoder(
        codingPath: codingPath + [BasicCodingKey.key("super")],
        configuration: configuration
      )
      childContainers["super"] = encoder
      return encoder
    }

    /// See `KeyedEncodingContainerProtocol`
    func superEncoder(forKey key: Key) -> any Encoder {
      let encoder = _Encoder(codingPath: codingPath + [key], configuration: configuration)
      childContainers[key.stringValue] = encoder
      return encoder
    }

    // MARK: Private

    private let configuration: URLEncodedFormEncoder.Configuration

  }

  /// Private `UnkeyedEncodingContainer`.
  private final class UnkeyedContainer: UnkeyedEncodingContainer, _Container {

    // MARK: Lifecycle

    init(codingPath: [any CodingKey], configuration: URLEncodedFormEncoder.Configuration) {
      self.codingPath = codingPath
      self.configuration = configuration
    }

    // MARK: Internal

    var codingPath: [any CodingKey]
    var count: Int = 0
    var internalData: URLEncodedFormData = []
    var childContainers: [Int: any _Container] = [:]

    func getData() throws -> URLEncodedFormData {
      var result = internalData
      for (key, childContainer) in childContainers {
        result.children[String(key)] = try childContainer.getData()
      }
      switch configuration.arrayEncoding {
      case .separator(let arraySeparator):
        var valuesToImplode = result.values
        result.values = []
        if
          case .bracket = configuration.arrayEncoding,
          let emptyStringChild = internalData.children[""]
        {
          valuesToImplode = valuesToImplode + emptyStringChild.values
          result.children[""]?.values = []
        }
        let implodedValue = try valuesToImplode.map { try $0.asURLEncoded() }
          .joined(separator: String(arraySeparator))
        result.values = [.urlEncoded(implodedValue)]
      case .bracket,
           .values:
        break
      }
      return result
    }

    func encodeNil() throws {
      // skip
    }

    func encode(_ value: some Encodable) throws {
      if let date = value as? Date {
        let encodedDate = try configuration.encodeDate(
          date,
          codingPath: codingPath,
          forKey: BasicCodingKey.index(count)
        )
        switch configuration.arrayEncoding {
        case .bracket:
          var emptyStringChild = internalData.children[""] ?? []
          emptyStringChild.values.append(contentsOf: encodedDate.values)
          internalData.children[""] = emptyStringChild
        case .separator,
             .values:
          internalData.values.append(contentsOf: encodedDate.values)
        }
      } else if let convertible = value as? any URLQueryFragmentConvertible {
        let value = convertible.urlQueryFragmentValue
        switch configuration.arrayEncoding {
        case .bracket:
          var emptyStringChild = internalData.children[""] ?? []
          emptyStringChild.values.append(value)
          internalData.children[""] = emptyStringChild
        case .separator,
             .values:
          internalData.values.append(value)
        }
      } else {
        let encoder = _Encoder(
          codingPath: codingPath + [BasicCodingKey.index(count)],
          configuration: configuration
        )
        try value.encode(to: encoder)
        let childData = try encoder.getData()
        if childData.hasOnlyValues {
          switch configuration.arrayEncoding {
          case .bracket:
            var emptyStringChild = internalData.children[""] ?? []
            emptyStringChild.values.append(contentsOf: childData.values)
            internalData.children[""] = emptyStringChild
          case .separator,
               .values:
            internalData.values.append(contentsOf: childData.values)
          }
        } else {
          internalData.children[count.description] = try encoder.getData()
        }
      }
      count += 1 // we don't want to do this if anything earlier threw an error
    }

    /// See UnkeyedEncodingContainer.nestedContainer
    func nestedContainer<NestedKey: CodingKey>(
      keyedBy _: NestedKey
        .Type
    ) -> KeyedEncodingContainer<NestedKey> {
      defer { self.count += 1 }
      let container = KeyedContainer<NestedKey>(
        codingPath: codingPath + [BasicCodingKey.index(count)],
        configuration: configuration
      )
      childContainers[count] = container
      return .init(container)
    }

    /// See UnkeyedEncodingContainer.nestedUnkeyedContainer
    func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
      defer { self.count += 1 }
      let container = UnkeyedContainer(
        codingPath: codingPath + [BasicCodingKey.index(count)],
        configuration: configuration
      )
      childContainers[count] = container
      return container
    }

    /// See UnkeyedEncodingContainer.superEncoder
    func superEncoder() -> any Encoder {
      defer { self.count += 1 }
      let encoder = _Encoder(
        codingPath: codingPath + [BasicCodingKey.index(count)],
        configuration: configuration
      )
      childContainers[count] = encoder
      return encoder
    }

    // MARK: Private

    private let configuration: URLEncodedFormEncoder.Configuration

  }

  /// Private `SingleValueEncodingContainer`.
  private final class SingleValueContainer: SingleValueEncodingContainer, _Container {

    // MARK: Lifecycle

    /// Creates a new single value encoder
    init(
      codingPath: [any CodingKey],
      configuration: URLEncodedFormEncoder.Configuration
    ) {
      self.codingPath = codingPath
      self.configuration = configuration
    }

    // MARK: Internal

    /// See `SingleValueEncodingContainer`
    var codingPath: [any CodingKey]

    /// The data being encoded
    var data: URLEncodedFormData = []

    func getData() throws -> URLEncodedFormData { data }

    /// See `SingleValueEncodingContainer`
    func encodeNil() throws {
      // skip
    }

    /// See `SingleValueEncodingContainer`
    func encode(_ value: some Encodable) throws {
      if let date = value as? Date {
        data = try configuration.encodeDate(date, codingPath: codingPath, forKey: nil)
      } else if let convertible = value as? any URLQueryFragmentConvertible {
        data.values.append(convertible.urlQueryFragmentValue)
      } else {
        let encoder = _Encoder(codingPath: codingPath, configuration: configuration)
        try value.encode(to: encoder)
        data = try encoder.getData()
      }
    }

    // MARK: Private

    private let configuration: URLEncodedFormEncoder.Configuration

  }

  private var container: (any _Container)?
  private let configuration: URLEncodedFormEncoder.Configuration

}

extension URLEncodedFormEncoder.Configuration {
  fileprivate func encodeDate(
    _ date: Date,
    codingPath: [any CodingKey],
    forKey key: (any CodingKey)?
  ) throws
    -> URLEncodedFormData
  {
    switch dateEncodingStrategy {
    case .secondsSince1970:
      return URLEncodedFormData(values: [date.urlQueryFragmentValue])
    case .iso8601:
      return URLEncodedFormData(values: [
        ISO8601DateFormatter().string(from: date).urlQueryFragmentValue,
      ])
    case .custom(let callback):
      let newCodingPath = codingPath + (key.map { [$0] } ?? [])
      let encoder = _Encoder(codingPath: newCodingPath, configuration: self)
      try callback(date, encoder)
      return try encoder.getData()
    }
  }
}

extension EncodingError {
  fileprivate static func invalidValue(_ value: Any, at path: [any CodingKey]) -> EncodingError {
    let pathString = path.map(\.stringValue).joined(separator: ".")
    let context = EncodingError.Context(
      codingPath: path,
      debugDescription: "Invalid value at '\(pathString)': \(value)"
    )
    return Swift.EncodingError.invalidValue(value, context)
  }
}
