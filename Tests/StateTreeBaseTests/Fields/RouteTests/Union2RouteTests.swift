import Disposable
import XCTest
@_spi(Implementation) @testable import StateTreeBase

// MARK: - Union2RouteTests

final class Union2RouteTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_Union2Route_A() async throws {
    let tree = Tree(root: NestedUnion2RouteHost(routeTo: .a))
    try tree.start()
    let root = try tree.assume.root
    XCTAssertNil(root.node.hosted?.b)
    let routed = try XCTUnwrap(root.node.hosted?.a)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )
  }

  @TreeActor
  func test_Union2Route_B() async throws {
    let tree = Tree(root: NestedUnion2RouteHost(routeTo: .b))
    try tree.start()
    let root = try tree.assume.root
    XCTAssertNil(root.node.hosted?.a)
    let routed = try XCTUnwrap(root.node.hosted?.b)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: BModel.self)
    )
  }

  @TreeActor
  func test_Union2Route_none() async throws {
    let tree = Tree(root: NestedUnion2RouteHost(routeTo: nil))
    try tree.start()
    let root = try tree.assume.root
    XCTAssertNil(root.node.hosted)
  }

  @TreeActor
  func test_Union2Route_reroute() async throws {
    let tree = Tree(root: NestedUnion2RouteHost(routeTo: .a))
    try tree.start()
    let root = try tree.assume.root
    XCTAssertNil(root.node.hosted?.b)
    let routed = try XCTUnwrap(root.node.hosted?.a)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )

    root.node.routeTo = .b
    XCTAssertNil(root.node.hosted?.a)
    let routed2 = try XCTUnwrap(root.node.hosted?.b)
    XCTAssertEqual(
      String(describing: type(of: routed2)),
      String(describing: BModel.self)
    )

    root.node.routeTo = nil
    XCTAssertNil(root.node.hosted)
  }

}

extension Union2RouteTests {

  enum Model: Codable {
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
    @Route var hosted: Union.Two<AModel, BModel>? = nil

    var rules: some Rules {
      if let routeTo {
        switch routeTo {
        case .a:
          Serve(.a(.init()), at: $hosted)
        case .b:
          Serve(.b(.init()), at: $hosted)
        }
      }
    }
  }
}
