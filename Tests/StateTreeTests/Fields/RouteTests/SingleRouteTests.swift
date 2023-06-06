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
    try tree.start()
    XCTAssertNotNil(try tree.assume.root)
    let routed = try XCTUnwrap(try tree.assume.rootNode.hosted)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )
  }

  @TreeActor
  func test_singleRoute_routeNone() async throws {
    let tree = Tree(root: SingleRouteHost(route: false))
    try tree.start()
    XCTAssertNotNil(try tree.assume.root)
    XCTAssertNil(try tree.assume.rootNode.hosted)
  }

  @TreeActor
  func test_singleRoute_reroute() async throws {
    let tree = Tree(root: SingleRouteHost(route: true))
    try tree.start()
    XCTAssertNotNil(try tree.assume.root)
    let routed = try XCTUnwrap(try tree.assume.rootNode.hosted)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )
    try tree.assume.rootNode.route = false
    XCTAssertNotNil(try tree.assume.root)
    XCTAssertNil(try tree.assume.rootNode.hosted)
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
    @Route var hosted: AModel? = nil

    var rules: some Rules {
      if route {
        Serve(AModel(), at: $hosted)
      }
    }
  }
}
