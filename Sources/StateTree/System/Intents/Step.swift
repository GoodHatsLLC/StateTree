import Foundation
import TreeState

// MARK: - Step

public struct Step: TreeState {

  // MARK: Lifecycle

  public init(step: Step) {
    self = step
  }

  public init(_ step: some IntentStep) {
    self.name = step.name()
    self.underlying = FieldDecoder(value: step)
  }

  public init(name: String, fields: [String: Any]) {
    self.name = name
    self.underlying = FieldDecoder(fields: fields)
  }

  // MARK: Public

  public let name: String

  // MARK: Internal

  func decode<Step: IntentStep>(as type: Step.Type) throws -> Step {
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
