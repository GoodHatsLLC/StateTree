// MARK: - URLPayloadStep

public struct URLPayloadStep: StepType, Codable, LosslessStringConvertible, Sendable {

  // MARK: Lifecycle

  public init?(_ description: String) {
    let stepsPayload = description
      .split(separator: "/")
      .map { String($0) }
    guard
      stepsPayload.count == 2,
      let name = stepsPayload[0].removingPercentEncoding
    else {
      return nil
    }
    self.name = name
    self.encodedPayload = stepsPayload[1]
  }

  public init(from step: some StepPayload) throws {
    self.name = step.getName()
    self.encodedPayload = try Self.encoder.encode(step)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let joinedPayload = try container.decode(String.self)
    self = try .init(joinedPayload)
      .orThrow(
        Intent.StepDeserializationError(
          payload: joinedPayload,
          into: URLPayloadStep.self
        )
      )
  }

  // MARK: Public

  public var description: String {
    let encName = name
      .addingPercentEncoding(
        withAllowedCharacters: URLEncoding.allowedCharacters
      )
    return "\(encName ?? "")/\(encodedPayload)"
  }

  public func erase() -> AnyStep {
    .url(self)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }

  public func getName() -> String {
    name
  }

  public func getPayload<T: StepPayload>(as _: T.Type) throws -> T {
    try Self.decoder.decode(T.self, from: encodedPayload)
  }

  // MARK: Private

  private static let encoder = URLEncodedFormEncoder()
  private static let decoder = URLEncodedFormDecoder()

  private let encodedPayload: String
  private let name: String
}

extension Intent {

  static func urlString(with steps: [any StepPayload]) throws -> String {
    let urlSteps = try steps.map { try URLPayloadStep(from: $0) }
    return (["steps"] + urlSteps.map(\.description)).joined(separator: "/")
  }

  static func from(urlEncoded: String) throws -> Intent? {
    // NOTE: the "/" character is percentage encoded by URLEncodedFormSerializer
    // and so can be used as a separator.
    let payload = urlEncoded.split(separator: "/", maxSplits: 1)
    guard
      payload.count == 2,
      payload[0] == "steps"
    else {
      throw URLEncoding.EncodingError()
    }
    let stepsPayload = payload[1]
      .split(separator: "/")
      .map { String($0) }
    guard stepsPayload.count % 2 == 0
    else {
      throw URLEncoding.EncodingError()
    }
    let joinedSteps = stepsPayload.enumerated()
      .reduce(into: [String]()) { partialResult, el in
        let val = el.element
        let isName = el.offset % 2 == 0
        if isName {
          partialResult.append(val)
        } else {
          partialResult[partialResult.count - 1] += "/\(val)"
        }
      }
    let steps = try joinedSteps
      .map { encodedStep in
        try URLPayloadStep(encodedStep).orThrow()
      }
    return Intent(steps: steps.map { Step($0) })
  }
}
