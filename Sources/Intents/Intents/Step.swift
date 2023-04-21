import Foundation

// MARK: - StepConvertible

public protocol StepConvertible {
  func getName() -> String
  func getPayload() throws -> AnyCodable
}

// MARK: - Step

public struct Step: Hashable, Codable, Sendable, StepConvertible {

  // MARK: Lifecycle

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

  private let payload: AnyCodable

}

// MARK: - UnmatchedIntentName

public struct UnmatchedIntentName: Error {
  public let target: String
  public let payload: String
}
