import Foundation

// MARK: - FieldDecoder

public struct FieldDecoder: Hashable, Codable, Sendable {

  public init(fields: [String: Any]) throws {
    self.fields = AnyCodable(fields)
    let encoder = JSONEncoder()
    _ = try encoder.encode(self.fields)
  }

  public init(value: some Codable) {
    self.fields = AnyCodable(value)
  }

  private let fields: AnyCodable

  public func decode<T: Codable>(as _: T.Type) throws -> T {
    let encoder = JSONEncoder()
    let data = try encoder.encode(fields)
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
  }
}

// MARK: - MemberwiseError

public enum MemberwiseError: Error {
  case nonDictFieldUncodableField(Any)
  case uncodableField(Error)
}
