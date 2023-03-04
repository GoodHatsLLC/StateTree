extension Collection {
  func compact<E>() -> [E] where E? == Element {
    compactMap { $0 }
  }
}

extension Collection {
  func indexed<Key: Hashable>(by path: KeyPath<Element, Key>) -> [Key: Element] {
    reduce(into: [Key: Element]()) { acc, curr in
      acc[curr[keyPath: path]] = curr
    }
  }
}
