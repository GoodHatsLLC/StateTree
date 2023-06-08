import Foundation
import Utilities

// MARK: - StepType

public protocol StepType: Codable, Hashable {
  func getName() -> String
  func getPayload<T: StepPayload>(as: T.Type) throws -> T
  func erase() -> AnyStep
}

// MARK: - StepPayload

public protocol StepPayload: StepType {
  static var name: String { get }
}

extension StepPayload {
  public func getName() -> String {
    Self.name
  }

  public func getPayload<T: StepPayload>(as _: T.Type) throws -> T {
    if let payload = self as? T {
      return payload
    } else {
      throw Intent.StepDeserializationError(payload: "\(Self.self)", into: T.self)
    }
  }

  public func erase() -> AnyStep {
    .json(try! .init(from: self))
  }
}

// MARK: - UnmatchedIntentName

public struct UnmatchedIntentName: Error {
  public let target: String
  public let payload: String
}

extension Intent {

  public struct InvalidStepError: Error { }

  public struct StepSerializationError: Error {
    init<T: StepType>(name: String, step: T) {
      self.name = name
      self.step = "\(step)"
      self.stepName = "\(T.self)"
    }

    let name: String
    let step: String
    let stepName: String
    var description: String {
      """
      Could not serialize step '\(name)' as \(stepName).
      \(step)
      """
    }
  }

  public struct StepDeserializationError: Error {
    init(payload: String, into: (some StepType).Type) {
      self.into = "\(into)"
      self.fromPayload = payload
    }

    let into: String
    let fromPayload: String
    var description: String {
      "Could not deserialize payload (\(fromPayload)) as into \(into)."
    }
  }
}
