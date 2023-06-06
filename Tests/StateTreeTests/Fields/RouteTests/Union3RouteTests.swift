import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - Union3RouteTests

final class Union3RouteTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_Union3Route_A() async throws {
    let tree = Tree(root: NestedUnion3RouteHost(routeTo: .a))
    try tree.start()
    XCTAssertNotNil(try tree.assume.root)
    XCTAssertNil(try tree.assume.rootNode.hosted?.b)
    XCTAssertNil(try tree.assume.rootNode.hosted?.c)
    let routed = try XCTUnwrap(try tree.assume.rootNode.hosted?.a)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )
  }

  @TreeActor
  func test_Union3Route_B() async throws {
    let tree = Tree(root: NestedUnion3RouteHost(routeTo: .b))
    try tree.start()
    XCTAssertNotNil(try tree.assume.root)
    XCTAssertNil(try tree.assume.rootNode.hosted?.a)
    XCTAssertNil(try tree.assume.rootNode.hosted?.c)
    let routed = try XCTUnwrap(try tree.assume.rootNode.hosted?.b)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: BModel.self)
    )
  }

  @TreeActor
  func test_Union3Route_C() async throws {
    let tree = Tree(root: NestedUnion3RouteHost(routeTo: .c))
    try tree.start()
    XCTAssertNotNil(try tree.assume.root)
    XCTAssertNil(try tree.assume.rootNode.hosted?.a)
    XCTAssertNil(try tree.assume.rootNode.hosted?.b)
    let routed = try XCTUnwrap(try tree.assume.rootNode.hosted?.c)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: CModel.self)
    )
  }

  @TreeActor
  func test_Union3Route_none() async throws {
    let tree = Tree(root: NestedUnion3RouteHost(routeTo: nil))
    try tree.start()
    XCTAssertNotNil(try tree.assume.root)
    XCTAssertNil(try tree.assume.rootNode.hosted?.a)
    XCTAssertNil(try tree.assume.rootNode.hosted?.b)
    XCTAssertNil(try tree.assume.rootNode.hosted?.c)
  }

  @TreeActor
  func test_Union3Route_reroute() async throws {
    let tree = Tree(root: NestedUnion3RouteHost(routeTo: .a))
    try tree.start()
    XCTAssertNotNil(try tree.assume.root)
    XCTAssertNil(try tree.assume.rootNode.hosted?.b)
    XCTAssertNil(try tree.assume.rootNode.hosted?.c)
    let routed = try XCTUnwrap(try tree.assume.rootNode.hosted?.a)
    XCTAssertEqual(
      String(describing: type(of: routed)),
      String(describing: AModel.self)
    )

    try tree.assume.rootNode.routeTo = .b
    XCTAssertNil(try tree.assume.rootNode.hosted?.a)
    XCTAssertNil(try tree.assume.rootNode.hosted?.c)
    let routed2 = try XCTUnwrap(try tree.assume.rootNode.hosted?.b)
    XCTAssertEqual(
      String(describing: type(of: routed2)),
      String(describing: BModel.self)
    )

    try tree.assume.rootNode.routeTo = nil
    XCTAssertNil(try tree.assume.rootNode.hosted)

    try tree.assume.rootNode.routeTo = .c
    XCTAssertNil(try tree.assume.rootNode.hosted?.a)
    XCTAssertNil(try tree.assume.rootNode.hosted?.b)
    let routed3 = try XCTUnwrap(try tree.assume.rootNode.hosted?.c)
    XCTAssertEqual(
      String(describing: type(of: routed3)),
      String(describing: CModel.self)
    )
  }

}

extension Union3RouteTests {

  enum Model: Codable {
    case a
    case b
    case c
  }

  // MARK: - NestedRoute

  struct AModel: Node {
    var rules: some Rules { .none }
  }

  // MARK: - BModel

  struct BModel: Node {
    var rules: some Rules { .none }
  }

  // MARK: - CModel

  struct CModel: Node {
    var rules: some Rules { .none }
  }

  // MARK: - NestedUnion3RouteHost

  struct NestedUnion3RouteHost: Node {

    @Value var routeTo: Model?
    @Route var hosted: Union.Three<AModel, BModel, CModel>? = nil

    var rules: some Rules {
      if let routeTo {
        switch routeTo {
        case .a:
          Serve(.a(AModel()), at: $hosted)
        case .b:
          Serve(.b(BModel()), at: $hosted)
        case .c:
          Serve(.c(CModel()), at: $hosted)
        }
      }
    }
  }
}
