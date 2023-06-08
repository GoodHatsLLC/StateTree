public enum AnyStep: Codable, Hashable, StepType, Sendable {
  case json(JSONPayloadStep)
  case url(URLPayloadStep)
  case invalid

  // MARK: Lifecycle

  public init(payload: some StepPayload) throws {
    self = .json(try .init(from: payload))
  }

  // MARK: Public

  public func getName() -> String {
    switch self {
    case .json(let jsonPayloadStep):
      return jsonPayloadStep.getName()
    case .url(let urlPayloadStep):
      return urlPayloadStep.getName()
    case .invalid:
      return "invalid"
    }
  }

  public func getPayload<T>(as _: T.Type) throws -> T where T: StepPayload {
    switch self {
    case .json(let jsonPayloadStep):
      return try jsonPayloadStep.getPayload(as: T.self)
    case .url(let urlPayloadStep):
      return try urlPayloadStep.getPayload(as: T.self)
    case .invalid:
      throw Intent.InvalidStepError()
    }
  }

  public func erase() -> AnyStep {
    self
  }
}
