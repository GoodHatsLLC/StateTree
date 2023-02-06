import HeapModule

// MARK: - PriorityItem

struct PriorityItem<Key: Comparable, Element> {

  let key: Key
  let element: Element
  private let differentiator: UInt32

  init(
    key: Key,
    element: Element,
    differentiator: UInt32
  ) {
    self.key = key
    self.element = element
    self.differentiator = differentiator
  }
}

// MARK: Comparable

extension PriorityItem: Comparable {

  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.key < rhs.key || (lhs.key == rhs.key && lhs.differentiator < rhs.differentiator)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.key == rhs.key && lhs.differentiator == rhs.differentiator
  }

}

// MARK: - PriorityQueue

struct PriorityQueue<Key: Comparable, Element> {

  // MARK: Lifecycle

  init(
    type _: Element.Type,
    prioritizeBy priority: KeyPath<Element, Key>,
    uniqueBy hashability: KeyPath<Element, some Hashable>? = nil
  ) {
    self.init(
      [Element](),
      prioritizeBy: { $0[keyPath: priority] },
      uniqueBy: hashability.map { hashPath in { AnyHashable($0[keyPath: hashPath]) } }
    )
  }

  init(
    _: some Sequence<Element>,
    prioritizeBy priority: KeyPath<Element, Key>,
    uniqueBy hashability: KeyPath<Element, some Hashable>? = nil
  ) {
    self.init(
      [Element](),
      prioritizeBy: { $0[keyPath: priority] },
      uniqueBy: hashability.map { hashPath in { AnyHashable($0[keyPath: hashPath]) } }
    )
  }

  private init(
    _ sequence: some Sequence<Element>,
    prioritizeBy priority: @escaping (Element) -> Key,
    uniqueBy hashability: ((Element) -> AnyHashable)?
  ) {
    var differentiator: UInt32 = 0
    self.resetDifferentiator = { differentiator = 0 }
    let make: (Element) -> PriorityItem<Key, Element> = { element in
      defer { differentiator += 1 }
      return PriorityItem(
        key: priority(element),
        element: element,
        differentiator: differentiator
      )
    }
    self.make = make
    if let hashable = hashability {
      var tracker = Set<AnyHashable>()
      self.shouldTrack = true
      let isTrackedFunc: (Element) -> Bool = { tracker.contains(AnyHashable(hashable($0))) }
      let addTrackingFunc: (Element) -> Void = { tracker.insert(AnyHashable(hashable($0))) }
      self.removeTrackingFunc = { tracker.remove(AnyHashable(hashable($0))) }
      self.isTrackedFunc = isTrackedFunc
      self.addTrackingFunc = addTrackingFunc
      let unique = sequence.filter { element in
        if isTrackedFunc(element) {
          return false
        } else {
          addTrackingFunc(element)
          return true
        }
      }
      self.heap = Heap(unique.map(make))
    } else {
      self.shouldTrack = false
      self.isTrackedFunc = { _ in false }
      self.addTrackingFunc = { _ in }
      self.removeTrackingFunc = { _ in }
      self.heap = Heap(sequence.map(make))
    }
  }

  // MARK: Internal

  @inlinable @inline(__always) var isEmpty: Bool {
    heap.isEmpty
  }

  @inlinable @inline(__always) var count: Int {
    heap.count
  }

  var min: Element? {
    heap.min()?.element
  }

  var max: Element? {
    heap.max()?.element
  }

  @discardableResult
  mutating func insert(_ element: Element) -> Bool {
    if !isTrackedFunc(element) {
      addTrackingFunc(element)
      heap.insert(
        make(element)
      )
      return true
    } else {
      return false
    }
  }

  @discardableResult
  mutating func popMin() -> Element? {
    guard let element = heap.popMin()?.element
    else {
      return nil
    }
    removeTrackingFunc(element)
    resetDifferentiatorIfEmpty()
    return element
  }

  @discardableResult
  mutating func popMax() -> Element? {
    guard let element = heap.popMax()?.element
    else {
      return nil
    }
    removeTrackingFunc(element)
    resetDifferentiatorIfEmpty()
    return element
  }

  // MARK: Private

  private var heap: Heap<PriorityItem<Key, Element>>
  private let make: (Element) -> PriorityItem<Key, Element>
  private let resetDifferentiator: () -> Void
  private let shouldTrack: Bool
  private let isTrackedFunc: (Element) -> Bool
  private let addTrackingFunc: (Element) -> Void
  private let removeTrackingFunc: (Element) -> Void

  @inline(__always)
  private mutating func resetDifferentiatorIfEmpty() {
    if heap.isEmpty {
      resetDifferentiator()
    }
  }

}
