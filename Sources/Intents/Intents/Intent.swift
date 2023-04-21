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
    let steps = try urlEncoded
      .split(separator: "/")
      .map { encodedStep in
        try Self.decoder.decode(Step.self, from: String(encodedStep))
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
    // NOTE: the "/" character is percentage encoded by URLEncodedFormSerializer
    // and so can be used as a separator.
    try steps.map { step in
      try Self.encoder.encode(step)
    }.joined(separator: "/")
  }

  // MARK: Private

  private static let encoder = URLEncodedFormEncoder()
  private static let decoder = URLEncodedFormDecoder()

  private let steps: [Step]

}
