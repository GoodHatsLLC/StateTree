import Dependencies

// MARK: - KeyOne

struct KeyOne: DependencyKey {
  static let defaultValue = false
}

// MARK: - KeyTwo

struct KeyTwo: DependencyKey {
  static let defaultValue = "default"
}

// MARK: - KeyThree

struct KeyThree: DependencyKey {
  static let defaultValue = Int.max
}

extension DependencyValues {
  var one: Bool {
    get { self[KeyOne.self] }
    set { self[KeyOne.self] = newValue }
  }

  var two: String {
    get { self[KeyTwo.self] }
    set { self[KeyTwo.self] = newValue }
  }

  var three: Int {
    get { self[KeyThree.self] }
    set { self[KeyThree.self] = newValue }
  }
}
