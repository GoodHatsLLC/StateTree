typealias EquatableError = Equatable & Error

// MARK: - TreeLifecycleError

enum TreeLifecycleError: Equatable, CustomStringConvertible {
  case alreadyStarted
  case inactive

  var description: String {
    switch self {
    case .alreadyStarted: return "The tree was already started."
    case .inactive: return "The tree is not active."
    }
  }
}

// MARK: - TreeErrorType

enum TreeErrorType: Error, CustomStringConvertible, Equatable {

  case known(error: TreeLifecycleError)
  case equatable(error: any EquatableError)

  // MARK: Internal

  var description: String {
    switch self {
    case .known(error: let error): return error.description
    case .equatable(error: let error): return error.localizedDescription
    }
  }

  var errorDescription: String {
    description
  }

  static func == (lhs: TreeErrorType, rhs: TreeErrorType) -> Bool {
    switch (lhs, rhs) {
    case (.known(error: let lhs), .known(error: let rhs)): return lhs == rhs
    case (.equatable(error: let lhs), .equatable(error: let rhs)): return Hoisted
      .equals(lhs: lhs, rhs: rhs)
    default: return false
    }
  }

  // MARK: Private

  private enum Hoisted {
    static func equals<LHS: EquatableError>(lhs: LHS, rhs: some EquatableError) -> Bool {
      if let rhs = rhs as? LHS {
        return rhs == lhs
      } else {
        return false
      }
    }
  }

}

// MARK: - TreeError

public struct TreeError: Error, CustomStringConvertible, Equatable {
  public var description: String {
    wrapped.description
  }

  public var errorDescription: String {
    description
  }

  init(_ error: TreeLifecycleError) {
    self.wrapped = .known(error: error)
  }

  public init(_ error: some Error) {
    if let error = error as? TreeLifecycleError {
      self.wrapped = .known(error: error)
    } else {
      let error = error as (any EquatableError)
      self.wrapped = .equatable(error: error)
    }
  }

  let wrapped: TreeErrorType
}
