import BehaviorInterface
import SourceLocation

// MARK: - MockBehaviorType

public protocol MockBehaviorType {
  var id: String { get }
  var isNoop: Bool { get }
  var outputType: String { get }
}

// MARK: - MockBehavior

public struct MockBehavior<Output> {

  public init(id: String, action: BehaviorInterception<Output>) {
    self.id = id
    self.action = action
  }

  public let id: String
  public let action: BehaviorInterception<Output>

  public var isNoop: Bool {
    switch action {
    case .cancel: return true
    case _: return false
    }
  }

  public var outputType: String {
    isNoop ? "NO_OP" : String(describing: Output.self)
  }

}

// MARK: - MissingBehaviors

public struct MissingBehaviors: Error {
  public init(
    missingBehaviors: [String],
    unexpectedBehaviors: [(id: String, initLocation: String, runLocation: String)]
  ) {
    self.missingBehaviors = missingBehaviors
    self.unexpectedBehaviors = unexpectedBehaviors
  }

  public let missingBehaviors: [String]
  public let unexpectedBehaviors: [(id: String, initLocation: String, runLocation: String)]
}
