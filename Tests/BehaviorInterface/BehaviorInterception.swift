// MARK: - BehaviorInterceptionType

public protocol BehaviorInterceptionType {
  var isCancel: Bool { get }
  func getAction<Output>(type: Output.Type) -> (() async throws -> Output)?
}

// MARK: - BehaviorInterception

public enum BehaviorInterception<Output>: BehaviorInterceptionType {
  case cancel
  case swap(action: () async throws -> Output)

  public var isCancel: Bool {
    switch self {
    case .cancel: return true
    case _: return false
    }
  }

  public func getAction<Output>(type _: Output.Type) -> (() async throws -> Output)? {
    switch self {
    case .cancel: return nil
    case .swap(action: let act):
      return act as? () async throws -> Output
    }
  }
}
