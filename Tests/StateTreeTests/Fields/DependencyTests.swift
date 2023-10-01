import Disposable
import Emitter
import StateTree
import XCTest

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
    XCTAssertEqual(node.value, SomeDependency(value: "Default Value"))
    XCTAssertEqual(node.hosted?.value, SomeDependency(value: "Some Other Value"))
    XCTAssertEqual(node.hosted?.hosted?.value, SomeDependency(value: "Another Other Value"))
  }

}

// MARK: - SomeDependency

private struct SomeDependency {
  var value: String
}

// MARK: DependencyKey

extension SomeDependency: DependencyKey {
  static let defaultValue = SomeDependency(value: "Default Value")
}

extension DependencyValues {
  fileprivate var myCustomValue: SomeDependency {
    get { self[SomeDependency.self] }
    set { self[SomeDependency.self] = newValue }
  }
}

extension DependencyTests {

  // MARK: - DependencyHost

  fileprivate struct DependencyHost: Node {

    @Route var hosted: DependencyUserOne? = nil

    @Dependency(\.myCustomValue) var value

    var rules: some Rules {
      $hosted.serve {
        DependencyUserOne()
      }.injecting {
        $0.myCustomValue = SomeDependency(value: "Some Other Value")
      }
    }
  }

  // MARK: - DependencyUserOne

  fileprivate struct DependencyUserOne: Node {

    @Dependency(\.myCustomValue) var value
    @Route var hosted: DependencyUserTwo? = nil
    var rules: some Rules {
      $hosted
        .serve {
          DependencyUserTwo()
        }
        .injecting {
          $0.myCustomValue = SomeDependency(value: "Another Other Value")
        }
    }
  }

  // MARK: - DependencyUserTwo

  fileprivate struct DependencyUserTwo: Node {
    @Dependency(\.myCustomValue) var value
    var rules: some Rules { .none }
  }

}
