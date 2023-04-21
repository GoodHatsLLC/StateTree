import Foundation

// MARK: - StepConvertible

public protocol StepConvertible {
  func getName() -> String
  func getPayload() throws -> AnyCodable
}

// MARK: - Step

public struct Step: Hashable, Codable, Sendable, StepConvertible, URLCodable {

  // MARK: Lifecycle

  public init(urlEncoded: String) throws {
    let components = urlEncoded.split(separator: "/")
    guard
      components.count == 2,
      let name = components[0].removingPercentEncoding
    else {
      throw URLEncoding.EncodingError()
    }
    let payloadComponent = String(components[1])
    self.name = name
    self.payload = try Self.decoder.decode(AnyCodable.self, from: payloadComponent)
  }

  public init(_ step: some StepConvertible) throws {
    self.name = step.getName()
    self.payload = try step.getPayload()
  }

  public init(name: String, fields: [String: Any]) throws {
    self.name = name
    let anyCodable = AnyCodable(fields)
    let data = try JSONEncoder().encode(anyCodable)
    self.payload = try JSONDecoder().decode(AnyCodable.self, from: data)
  }

  // MARK: Public

  public static var invalid: Step {
    try! Step(name: "__invalid", fields: ["invalid": "invalid"])
  }

  public let name: String

  public func urlEncode() throws -> String {
    guard
      let name = name
        .addingPercentEncoding(withAllowedCharacters: URLEncoding.allowedCharacters)
    else {
      throw URLEncoding.EncodingError()
    }
    let payload = try Self.encoder.encode(payload)
    return "\(name)/\(payload)"
  }

  public func decode<Step: IntentStepPayload>(as type: Step.Type) throws -> Step {
    guard type.name == name
    else {
      throw UnmatchedIntentName(target: type.name, payload: name)
    }
    let data = try JSONEncoder().encode(payload)
    return try JSONDecoder().decode(Step.self, from: data)
  }

  public func getName() -> String {
    name
  }

  public func getPayload() throws -> AnyCodable {
    payload
  }

  // MARK: Private

  private static let encoder = URLEncodedFormEncoder()
  private static let decoder = URLEncodedFormDecoder()

  private let payload: AnyCodable

}

// MARK: - UnmatchedIntentName

public struct UnmatchedIntentName: Error {
  public let target: String
  public let payload: String
}
