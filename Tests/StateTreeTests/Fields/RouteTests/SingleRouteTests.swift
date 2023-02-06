import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - SingleRouteTests

@TreeActor
final class SingleRouteTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  func test_singleRoute_route() throws {
    let tree = try Tree.main
      .start(root: SingleRouteHost(route: true))
    tree.stage(on: stage)
    XCTAssertNotNil(tree.root)
    let routed = try XCTUnwrap(tree.rootNode.hosted)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )
  }

  func test_singleRoute_routeNone() throws {
    let tree = try Tree.main
      .start(root: SingleRouteHost(route: false))
    tree.stage(on: stage)
    XCTAssertNotNil(tree.root)
    XCTAssertNil(tree.rootNode.hosted)
  }

  func test_singleRoute_reroute() throws {
    let tree = try Tree.main
      .start(root: SingleRouteHost(route: true))
    tree.stage(on: stage)
    XCTAssertNotNil(tree.root)
    let routed = try XCTUnwrap(tree.rootNode.hosted)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )
    tree.rootNode.route = false
    XCTAssertNotNil(tree.root)
    XCTAssertNil(tree.rootNode.hosted)
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
