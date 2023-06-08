// MARK: - URLCodable

public protocol URLCodable {
  func urlEncode() throws -> String
  init(urlEncoded: String) throws
}

// MARK: - Intent

public struct Intent: Hashable & Codable, Sendable {

  // MARK: Lifecycle

  public init?(
    _ steps: any StepType...
  ) {
    self.init(steps: steps.map { Step($0) })
  }

  public init?(
    steps: any Collection<Step>
  ) {
    self.steps = Array(steps)
    if steps.isEmpty {
      return nil
    }
  }

  // MARK: Public

  public var isEmpty: Bool {
    steps.first == nil
  }

  public var head: Step? {
    steps.first
  }

  public var tail: Intent? {
    Intent(steps: steps.dropFirst())
  }

  // MARK: Private

  private static let encoder = URLEncodedFormEncoder()
  private static let decoder = URLEncodedFormDecoder()

  private let steps: [Step]

}
