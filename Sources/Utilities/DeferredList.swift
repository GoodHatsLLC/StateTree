// MARK: - DeferredList

public struct DeferredList<Index: Comparable & Strideable, Element, Failure: Error> {
  public init(
    indices: Range<Index>,
    producer: @escaping (Index) -> Result<Element, Failure>
  ) {
    self.producer = producer
    self.startIndex = indices.lowerBound
    self.endIndex = indices.upperBound
  }

  public let startIndex: Index
  public let endIndex: Index
  let producer: (Index) -> Result<Element, Failure>
}

extension DeferredList where Failure == Never {
  public func element(at index: Index) -> Element {
    switch producer(index) {
    case .success(let value):
      return value
    }
  }

  public subscript(position: Index) -> Element {
    element(at: position)
  }

}

extension DeferredList {
  public func element(at index: Index) throws -> Element {
    try producer(index).get()
  }
}

// MARK: Sequence

extension DeferredList: Sequence { }

// MARK: Collection

extension DeferredList: Collection { }

// MARK: BidirectionalCollection

extension DeferredList: BidirectionalCollection { }

// MARK: RandomAccessCollection

extension DeferredList: RandomAccessCollection {

  public func index(before i: Index) -> Index {
    i.advanced(by: -1)
  }

  public func index(after i: Index) -> Index {
    i.advanced(by: 1)
  }

  public subscript(position: Index) -> Element {
    try! element(at: position)
  }
}
