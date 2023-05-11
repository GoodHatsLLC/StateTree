import OrderedCollections

extension Collection {
  func compact<E>() -> [E] where E? == Element {
    compactMap { $0 }
  }
}

extension Collection {
  func indexed<Key: Hashable>(by path: KeyPath<Element, Key>)
    -> [Key: Element]
  {
    reduce(into: [Key: Element]()) { acc, curr in
      acc[curr[keyPath: path]] = curr
    }
  }
}

extension Collection {
  func orderedIndexed<Key: Hashable>(by path: KeyPath<Element, Key>)
    -> OrderedDictionary<Key, Element>
  {
    reduce(into: OrderedDictionary<Key, Element>()) { acc, curr in
      acc[curr[keyPath: path]] = curr
    }
  }
}

extension Collection {
  func at(index: Index) -> Element? {
    if endIndex > index {
      return self[index]
    } else {
      return nil
    }
  }
}
