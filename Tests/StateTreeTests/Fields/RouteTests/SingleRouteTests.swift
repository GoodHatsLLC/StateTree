import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - SingleRouteTests

final class SingleRouteTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_singleRoute_route() async throws {
    let tree = Tree(root: SingleRouteHost(route: true))
    await tree.run(on: stage)
    XCTAssertNotNil(try tree.root)
    let routed = try XCTUnwrap(try tree.rootNode.hosted)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )
  }

  @TreeActor
  func test_singleRoute_routeNone() async throws {
    let tree = Tree(root: SingleRouteHost(route: false))
    await tree.run(on: stage)
    XCTAssertNotNil(try tree.root)
    XCTAssertNil(try tree.rootNode.hosted)
  }

  @TreeActor
  func test_singleRoute_reroute() async throws {
    let tree = Tree(root: SingleRouteHost(route: true))
    await tree.run(on: stage)
    XCTAssertNotNil(try tree.root)
    let routed = try XCTUnwrap(try tree.rootNode.hosted)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )
    try tree.rootNode.route = false
    XCTAssertNotNil(try tree.root)
    XCTAssertNil(try tree.rootNode.hosted)
  }
}

extension SingleRouteTests {

  // MARK: - NestedRoute

  struct AModel: Node {
    var rules: some Rules { .none }
  }

  // MARK: - NestedRouteHost

  struct SingleRouteHost: Node {

    @Value var route: Bool
    @Route(AModel.self) var hosted

    var rules: some Rules {
      if route {
        $hosted
          .route { AModel() }
      }
    }
  }
}
