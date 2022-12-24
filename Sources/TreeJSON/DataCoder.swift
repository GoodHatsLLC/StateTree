import Foundation

// MARK: - Decoder

/// A type that defines methods for decoding.
public protocol Decoder {

  /// The type of the value decoded.
  associatedtype Input

  /// Decodes an instance of the indicated type.
  func decode<T>(_ type: T.Type, from: Input) throws -> T where T: Decodable
}

// MARK: - Encoder

/// A type that defines methods for encoding.
public protocol Encoder {

  /// The type this encoder produces.
  associatedtype Output

  /// Encodes an instance of the indicated type.
  ///
  /// - Parameter value: The instance to encode.
  func encode<T>(_ value: T) throws -> Output where T: Encodable
}

// MARK: - Coder

public protocol Coder: Decoder, Encoder {}
