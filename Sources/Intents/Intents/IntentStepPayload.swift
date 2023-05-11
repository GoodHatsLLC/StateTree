import Foundation
import Utilities

// MARK: - IntentStepPayload

public protocol IntentStepPayload: Codable, StepConvertible {
  static var name: String { get }
}

extension IntentStepPayload {
  public func getName() -> String {
    Self.name
  }

  public func getPayload() throws -> AnyCodable {
    let anyCodable = AnyCodable(self)
    let data = try JSONEncoder().encode(anyCodable)
    return try JSONDecoder().decode(AnyCodable.self, from: data)
  }
}
