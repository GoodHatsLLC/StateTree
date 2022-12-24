import Foundation

// MARK: - JSONStringCoder

public struct JSONStringCoder: Coder {

  public init() {}

  public enum Failure: Error {
    case stringEncodingError
    case stringDecodingError
  }

  public func encode<T>(
    _ value: T
  )
    throws -> String where T: Encodable
  {
    let data = try Self.encoder.encode(value)
    guard let jsonString = String(data: data, encoding: .utf8)
    else {
      throw Failure.stringEncodingError
    }
    return jsonString
  }

  public func decode<T>(
    _ type: T.Type,
    from jsonString: String
  )
    throws -> T where T: Decodable
  {
    guard let data = jsonString.data(using: .utf8)
    else {
      throw Failure.stringDecodingError
    }
    return try Self.decoder.decode(type, from: data)
  }

  private static let encoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    return encoder
  }()

  private static let decoder = JSONDecoder()

}
