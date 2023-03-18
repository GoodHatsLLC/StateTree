// MARK: - ProducerType

public protocol ProducerType<Resolution> {
  associatedtype Resolution: ResolverType
}

// MARK: - SingleProducerType

public protocol SingleProducerType<Resolution>: ProducerType where Resolution: SingleResolverType {
  init(value: Resolution)
  var value: Resolution { get }
}

// MARK: - One

public struct One<Resolution: SingleResolverType>: SingleProducerType {
  public init(value: Resolution) {
    self.value = value
  }

  public let value: Resolution
}
