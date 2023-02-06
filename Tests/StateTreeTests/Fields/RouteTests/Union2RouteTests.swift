import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - Union2RouteTests

@TreeActor
final class Union2RouteTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  func test_Union2Route_A() throws {
    let tree = try Tree.main
      .start(root: NestedUnion2RouteHost(routeTo: .a))
    tree.stage(on: stage)
    XCTAssertNotNil(tree.root)
    XCTAssertNil(tree.rootNode.hosted?.b)
    let routed = try XCTUnwrap(tree.rootNode.hosted?.a)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )
  }

  func test_Union2Route_B() throws {
    let tree = try Tree.main
      .start(root: NestedUnion2RouteHost(routeTo: .b))
    tree.stage(on: stage)
    XCTAssertNotNil(tree.root)
    XCTAssertNil(tree.rootNode.hosted?.a)
    let routed = try XCTUnwrap(tree.rootNode.hosted?.b)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: BModel.self)
    )
  }

  func test_Union2Route_none() throws {
    let tree = try Tree.main
      .start(root: NestedUnion2RouteHost(routeTo: nil))
    tree.stage(on: stage)
    XCTAssertNotNil(tree.root)
    XCTAssertNil(tree.rootNode.hosted)
  }

  func test_Union2Route_reroute() throws {
    let tree = try Tree.main
      .start(root: NestedUnion2RouteHost(routeTo: .a))
    tree.stage(on: stage)
    XCTAssertNotNil(tree.root)
    XCTAssertNil(tree.rootNode.hosted?.b)
    let routed = try XCTUnwrap(tree.rootNode.hosted?.a)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )

    tree.rootNode.routeTo = .b
    XCTAssertNil(tree.rootNode.hosted?.a)
    let routed2 = try XCTUnwrap(tree.rootNode.hosted?.b)
    XCTAssertEqual(
      String(describing: type(of: routed2)),
      String(describing: BModel.self)
    )

    tree.rootNode.routeTo = nil
    XCTAssertNil(tree.rootNode.hosted)
  }

}

extension Union2RouteTests {

  enum Model: TreeState {
    case a
    case b
  }

  // MARK: - NestedRoute

  struct AModel: Node {
    var rules: some Rules { .none }
  }

  // MARK: - BModel

  struct BModel: Node {
    var rules: some Rules { .none }
  }

  // MARK: - NestedUnion2RouteHost

  struct NestedUnion2RouteHost: Node {

    @Value var routeTo: Model?
    @Route(AModel.self, BModel.self) var hosted

    var rules: some Rules {
      if let routeTo {
        switch routeTo {
        case .a:
          $hosted
            .route { .a(AModel()) }
        case .b:
          $hosted
            .route { .b(BModel()) }
        }
      }
    }
  }
}
