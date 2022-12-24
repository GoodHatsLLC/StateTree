import Dependencies
import ModelInterface
import Utilities

// MARK: - RawState

@MainActor
@propertyWrapper
public struct RawState<M: Model> {

  public init(projectedValue: Store<M>) {
    self.projectedValue = projectedValue
  }

  public let projectedValue: Store<M>

  public var wrappedValue: M.State {
    projectedValue._storage.state
  }

}
