import Dependencies

// MARK: - TestOneKey

struct TestOneKey: DependencyKey {
  static let defaultValue = "DEFAULT_VALUE"
}

// MARK: - SomeClass

final class SomeClass {

  init(someField: Int = 0) {
    self.someField = someField
  }

  var someField = 0
}

// MARK: - TestTwoKey

struct TestTwoKey: DependencyKey {
  static let defaultValue = SomeClass()
}

extension DependencyValues {
  var testOne: String {
    get { self[TestOneKey.self] }
    set { self[TestOneKey.self] = newValue }
  }

  var testTwo: SomeClass {
    get { self[TestTwoKey.self] }
    set { self[TestTwoKey.self] = newValue }
  }

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
