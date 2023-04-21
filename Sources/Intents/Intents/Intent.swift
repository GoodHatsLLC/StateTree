// MARK: - URLCodable

public protocol URLCodable {
  func urlEncode() throws -> String
  init(urlEncoded: String) throws
}

// MARK: - Intent

public struct Intent: Hashable, Codable, Sendable, URLCodable {

  // MARK: Lifecycle

  public init(urlEncoded: String) throws {
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
        try Step(urlEncoded: encodedStep)
      }
    self.steps = steps
  }

  public init(_ steps: any StepConvertible...) throws {
    self.steps = try steps.map { try Step($0) }
  }

  private init?(
    steps: some Collection<Step>
  ) {
    guard !steps.isEmpty
    else {
      return nil
    }
    self.steps = Array(steps)
  }

  // MARK: Public

  public static var invalid: Intent {
    .init(steps: [Step.invalid])!
  }

  public var head: Step {
    steps.first!
  }

  public var tail: Intent? {
    Intent(steps: steps.dropFirst())
  }

  public func urlEncode() throws -> String {
    (try ["steps"] + steps.map { step in
      try step.urlEncode()
    }).joined(separator: "/")
  }

  // MARK: Private

  private static let encoder = URLEncodedFormEncoder()
  private static let decoder = URLEncodedFormDecoder()

  private let steps: [Step]

}
