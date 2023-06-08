import Foundation

public struct JSONPayloadStep: StepType, Sendable {

  // MARK: Lifecycle

  public init(from step: some StepPayload) throws {
    self.name = step.getName()
    let data = try Self.encoder.encode(step)
    self.encodedPayload = try String(data: data, encoding: .utf8)
      .orThrow(Intent.StepSerializationError(name: step.getName(), step: step))
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.encodedPayload = try container.decode(String.self, forKey: .payload)
  }

  // MARK: Public

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(encodedPayload, forKey: .payload)
  }

  public func getName() -> String {
    name
  }

  public func getPayload<T: StepPayload>(as _: T.Type) throws -> T {
    let data = try encodedPayload.data(using: .utf8)
      .orThrow(
        Intent.StepDeserializationError(
          payload: encodedPayload,
          into: T.self
        )
      )
    return try Self.decoder.decode(T.self, from: data)
  }

  public func erase() -> AnyStep {
    .json(self)
  }

  // MARK: Internal

  enum CodingKeys: CodingKey {
    case name
    case payload
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

  private let encodedPayload: String
  private let name: String
}
