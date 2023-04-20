import Foundation

// MARK: - Step

public struct Step: Hashable, Codable, Sendable {

  // MARK: Lifecycle

  public init(step: Step) {
    self = step
  }

  public init(_ step: some IntentStep) {
    self.name = step.name()
    self.underlying = FieldDecoder(value: step)
  }

  public init(name: String, fields: [String: Any]) throws {
    self.name = name
    self.underlying = try FieldDecoder(fields: fields)
  }

  // MARK: Public

  public let name: String

  public func decode<Step: IntentStep>(as type: Step.Type) throws -> Step {
    guard type.name == name
    else {
      throw IntentStepDecodingError.unmatchedName
    }
    return try underlying.decode(as: Step.self)
  }

  // MARK: Private

  private let underlying: FieldDecoder

}

// MARK: - IntentStepDecodingError

public enum IntentStepDecodingError: Error {
  case unmatchedName
  case typeMismatch
  case typeDecoding(Error)
}
