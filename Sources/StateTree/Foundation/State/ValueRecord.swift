import Foundation
import Utilities

// MARK: - ValuePayload

/// Value types aren't known at decoding time so their representation is kept as strings until
/// they can be decoded *as* a desired value. Until then the string representation is used
/// for any comparison and hashing.
public enum ValuePayload: TreeState {
  case runtime(known: any TreeState, stringPayload: String)
  case decoded(stringPayload: String)

  // MARK: Lifecycle

  public init(_ value: some TreeState) throws {
    let payload = try Self.encodedString(from: value)
    self = .runtime(known: value, stringPayload: payload)
  }

  public init(from coder: any Decoder) throws {
    let container = try coder.singleValueContainer()
    let payload = try container.decode(String.self)
    self = .decoded(
      stringPayload: payload
    )
  }

  // MARK: Public

  public struct ExtractionError: Error, CustomStringConvertible {
    public let description: String
  }

  public struct StringEncodingError: Error, CustomStringConvertible {
    public let description: String
  }

  public struct StringDecodingError: Error, CustomStringConvertible {
    public let description: String
  }

  public static func == (lhs: ValuePayload, rhs: ValuePayload) -> Bool {
    lhs.payload == rhs.payload
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(payload)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(payload)
  }

  public mutating func extract<T: TreeState>(as _: T.Type) throws -> T {
    switch self {
    case .runtime(let known, _):
      if let known = known as? T {
        return known
      } else {
        let knownType = type(of: known)
        throw ExtractionError(
          description: "Attempted to extract \(T.self) when runtime value was \(String(describing: knownType))"
        )
      }
    case .decoded(let payload):
      guard let data = payload.data(using: .utf8)
      else {
        throw StringDecodingError(description: "could not decode string payload into data")
      }

      let extracted = try Self.decoder.decode(T.self, from: data)
      self = .runtime(known: extracted, stringPayload: payload)
      return extracted
    }
  }

  public mutating func embed<T: TreeState>(value: T) throws {
    assert(
      (try? extract(as: T.self)) != nil,
      "DEBUG assert: attempted to embed a different or non-extractable value type"
    )
    runtimeWarning("DEBUG warning: attempted to embed a different or non-extractable value type")
    let payload = try Self.encodedString(from: value)
    self = .runtime(known: value, stringPayload: payload)
  }

  // MARK: Private

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dataDecodingStrategy = .base64
    return decoder
  }()

  private static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    encoder.dataEncodingStrategy = .base64
    return encoder
  }()

  private var payload: String {
    switch self {
    case .decoded(let stringPayload),
         .runtime(_, let stringPayload):
      return stringPayload
    }
  }

  private static func encodedString(from value: some TreeState) throws -> String {
    let data = try Self.encoder.encode(value)
    guard let stringPayload = String(data: data, encoding: .utf8)
    else {
      throw StringEncodingError(description: "Couldn't string encode value: \(value)")
    }
    return stringPayload
  }

}
