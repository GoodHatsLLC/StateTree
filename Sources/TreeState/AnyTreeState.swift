// MARK: - AnyTreeState

public struct AnyTreeState: Equatable,
  Hashable,
  Codable,
  @unchecked
Sendable {

  // MARK: Lifecycle

  public init(from decoder: Decoder) throws {
    let storage = try AnyCodable(from: decoder)
    guard
      let value = storage.value as? (any TreeStateNonSendable)
    else {
      throw InvalidTreeState.errorFor(assumption: (any TreeStateNonSendable).self)
    }
    self._runtime = value
  }

  public init(_ state: some TreeState) {
    self._runtime = state
  }

  // MARK: Public

  public var anyValue: any TreeState {
    _runtime
  }

  public static func == (lhs: AnyTreeState, rhs: AnyTreeState) -> Bool {
    lhs._runtime.equals(rhs._runtime)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(_runtime)
  }

  public func encode(to encoder: Encoder) throws {
    try AnyCodable(_runtime).encode(to: encoder)
  }

  // MARK: Internal

  var _runtime: any TreeState

  func get<T: TreeState>(as _: T.Type) throws -> T {
    if let value = anyValue as? T {
      value
    } else {
      throw InvalidTreeState.errorFor(assumption: T.self, state: self)
    }
  }

  mutating func set(to value: some TreeState) throws {
    _runtime = value
  }

}

extension Hashable where Self: TreeState {
  fileprivate func equals<T: TreeState>(_ other: T) -> Bool {
    (self as? T) == other
  }
}
