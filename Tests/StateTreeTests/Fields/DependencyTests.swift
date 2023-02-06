import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - DependencyTests

@TreeActor
final class DependencyTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { XCTAssertNil(Tree.main._info) }
  override func tearDown() {
    stage.reset()
  }

  func test_dependencyInjection() throws {
    let tree = try Tree.main
      .start(root: DependencyHost())
    tree.stage(on: stage)
    XCTAssertEqual(tree.rootNode.value, "Default Value")
    XCTAssertEqual(tree.rootNode.hosted?.value, "Some Other Value")
    XCTAssertEqual(tree.rootNode.hosted?.hosted?.value, "Another Other Value")
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