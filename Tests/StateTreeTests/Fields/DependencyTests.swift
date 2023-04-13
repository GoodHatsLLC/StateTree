import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - DependencyTests

final class DependencyTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_dependencyInjection() async throws {
    let tree = Tree(root: DependencyHost())
    _ = try tree.start()
    let node = try tree.assume.rootNode
    XCTAssertEqual(node.value, "Default Value")
    XCTAssertEqual(node.hosted?.value, "Some Other Value")
    XCTAssertEqual(node.hosted?.hosted?.value, "Another Other Value")
  }

}

// MARK: - TestDependencyKey

private struct TestDependencyKey: DependencyKey {
  static let defaultValue = "Default Value"
}

extension DependencyValues {
  fileprivate var myCustomValue: String {
    get { self[TestDependencyKey.self] }
    set { self[TestDependencyKey.self] = newValue }
  }
}

extension DependencyTests {

  // MARK: - DependencyHost

  struct DependencyHost: Node {

    @Route(DependencyUserOne.self) var hosted

    @Dependency(\.myCustomValue) var value

    var rules: some Rules {
      Inject(\.myCustomValue, "Some Other Value") {
        $hosted
          .route { DependencyUserOne() }
      }
    }
  }

  // MARK: - DependencyUserOne

  struct DependencyUserOne: Node {

    @Dependency(\.myCustomValue) var value
    @Route(DependencyUserTwo.self) var hosted
    var rules: some Rules {
      Inject(\.myCustomValue, "Another Other Value") {
        $hosted
          .route { DependencyUserTwo() }
      }
    }
  }

  // MARK: - DependencyUserTwo

  struct DependencyUserTwo: Node {
    @Dependency(\.myCustomValue) var value
    var rules: some Rules { .none }
  }

}
