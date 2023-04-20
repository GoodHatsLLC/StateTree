import Foundation

// MARK: - FieldDecoder

public struct FieldDecoder: Hashable, Codable, Sendable {

  public init(fields: [String: Any]) {
    self.fields = AnyCodable(fields)
  }

  public init(value: some Codable) {
    self.fields = AnyCodable(value)
  }

  private let fields: AnyCodable

  func decode<T: Codable>(as _: T.Type) throws -> T {
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
