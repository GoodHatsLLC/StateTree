import Disposable
import StateTree
import XCTest

// MARK: - PlaybackTests

final class PlaybackTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() {
    NodeID
      .incrementForTesting()
      .stage(on: stage)
  }

  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_startFrom() async throws {
    let tree = Tree(
        root: RootNode()
      )
    await tree.run(on: stage)
    XCTAssertNil(try tree.rootNode.subRoute)
    let initialState = try tree.snapshot()
    // print("INITIAL")
    // dump(initialState)
    try tree.rootNode.routeIfNegative = -2
    try tree.rootNode.subRoute?.subValue = 123
    let laterState = try tree.snapshot()
    // print("LATER")
    // dump(laterState)
    XCTAssertEqual(try tree.rootNode.routeIfNegative, -2)
    XCTAssertEqual(try tree.rootNode.subRoute?.value, -2)
    XCTAssertEqual(try tree.rootNode.subRoute?.subValue, 123)
    XCTAssertNotNil(try tree.rootNode.subRoute)
    stage.reset()

    let restartHandle = Tree(
      root: RootNode()
    )
    await tree.run(from: laterState, on: stage)

    let replayedState = try restartHandle.snapshot()
    // print("REPLAYED")
    // dump(replayedState)
    XCTAssertEqual(try restartHandle.rootNode.routeIfNegative, -2)
    XCTAssertNotNil(try restartHandle.rootNode.subRoute)
    XCTAssertEqual(try restartHandle.rootNode.subRoute?.value, -2)
    XCTAssertEqual(try restartHandle.rootNode.subRoute?.subValue, 123)
    XCTAssertEqual(replayedState, laterState)
    XCTAssertNotEqual(replayedState, initialState)
    stage.reset()
  }

  @TreeActor
  func test_setState() async throws {
    let tree = Tree(
        root: RootNode()
      )
    await tree.run(on: stage)

    let initialState = try tree.snapshot()

    try tree.rootNode.routeIfNegative = -2
    try tree.rootNode.subRoute?.subValue = 2
    let laterState = try tree.snapshot()
    XCTAssert(try tree.info.isConsistent == true)

    try tree.rootNode.routeIfNegative = -3
    let finalState = try tree.snapshot()

    try tree.set(state: initialState)
    XCTAssert(try tree.info.isConsistent == true)
    XCTAssertEqual(try tree.rootNode.routeIfNegative, 0)
    XCTAssertNil(try tree.rootNode.subRoute)

    try tree.set(state: laterState)
    XCTAssert(try tree.info.isConsistent == true)
    XCTAssertEqual(try tree.rootNode.routeIfNegative, -2)
    XCTAssertEqual(try tree.rootNode.subRoute?.subValue, 2)
    XCTAssertEqual(try tree.rootNode.subRoute?.subSubRoute?.value, -2)

    let recapture = try tree.snapshot()
    XCTAssertEqual(laterState, recapture)

    try tree.rootNode.routeIfNegative = -3
    let finalRecapture = try tree.snapshot()

    XCTAssertEqual(finalState, finalRecapture)
    stage.reset()
  }

  @TreeActor
  func test_setState_thrash() async throws {
    let lifetime = Tree(
        root: PrimeSquare()
      )
    await lifetime.run(on: stage)
    XCTAssertEqual(try lifetime.rootNode.primeSquared?.square, nil)
    let snap0 = try lifetime.snapshot()
    XCTAssertEqual(try lifetime.info.nodeCount, 1)

    try lifetime.rootNode.potentialPrime = 2
    XCTAssertEqual(try lifetime.rootNode.primeSquared?.square, 4)
    XCTAssertEqual(try lifetime.info.nodeCount, 2)
    let snap1 = try lifetime.snapshot()

    try lifetime.rootNode.potentialPrime = 4
    XCTAssertEqual(try lifetime.rootNode.primeSquared?.square, nil)
    let snap2 = try lifetime.snapshot()
    XCTAssertEqual(try lifetime.info.nodeCount, 1)

    try lifetime.rootNode.potentialPrime = 7
    XCTAssertEqual(try lifetime.rootNode.primeSquared?.square, 49)
    let snap3 = try lifetime.snapshot()
    XCTAssertEqual(try lifetime.info.nodeCount, 2)

    stage.reset()
    XCTAssertEqual(try lifetime.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(try lifetime.info.nodeCount, 0)

    let lifetime2 = Tree(
        root: PrimeSquare()
      )
    await lifetime2.run(from: snap3, on: stage)

    XCTAssertEqual(try lifetime2.rootNode.primeSquared?.square, 49)
    XCTAssertEqual(try lifetime2.info.nodeCount, 2)

    try lifetime2.set(state: snap0)
    XCTAssert(try lifetime2.info.isConsistent == true)
    XCTAssertEqual(try lifetime.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(try lifetime2.info.nodeCount, 1)

    try lifetime2.set(state: snap1)
    XCTAssert(try lifetime2.info.isConsistent == true)
    XCTAssertEqual(try lifetime2.rootNode.primeSquared?.square, 4)
    XCTAssertEqual(try lifetime2.info.nodeCount, 2)

    try lifetime2.set(state: snap0)
    XCTAssert(try lifetime2.info.isConsistent == true)
    XCTAssertEqual(try lifetime2.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(try lifetime2.info.nodeCount, 1)

    try lifetime2.set(state: snap3)
    XCTAssert(try lifetime2.info.isConsistent == true)
    XCTAssertEqual(try lifetime2.rootNode.primeSquared?.square, 49)
    XCTAssertEqual(try lifetime2.info.nodeCount, 2)

    try lifetime2.set(state: snap2)
    XCTAssert(try lifetime2.info.isConsistent == true)
    XCTAssertEqual(try lifetime2.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(try lifetime2.info.nodeCount, 1)

    stage.reset()
    XCTAssertFalse(try lifetime2.info.isActive)
    XCTAssertEqual(try lifetime2.rootNode.primeSquared?.square, nil)
  }

}

extension PlaybackTests {

  // MARK: - Square

  struct SubSubNode: Node {
    @Projection var value: Int
    var rules: some Rules { .none }
  }

  struct SubNode: Node {

    @Route(SubSubNode.self) var subSubRoute
    @Value var subValue = 32
    @Projection var value: Int

    var rules: some Rules {
      if subValue == 2 {
        $subSubRoute.route {
          SubSubNode(value: $value)
        }
      }
    }
  }

  // MARK: - RootNode

  struct RootNode: Node {

    @Value var routeIfNegative = 0
    @Route(SubNode.self) var subRoute

    var rules: some Rules {
      if routeIfNegative < 0 {
        $subRoute.route {
          SubNode(value: $routeIfNegative)
        }
      }
    }
  }

  // MARK: - Square

  struct Square: Node {

    @Value var square: Int!
    @Projection var value: Int

    var rules: some Rules {
      OnChange(value) { value in
        square = value * value
      }
    }
  }

  // MARK: - PrimeSquare

  struct PrimeSquare: Node {

    @Value var potentialPrime = 0
    @Route(Square.self) var primeSquared

    var rules: some Rules {
      if isPrime(potentialPrime) {
        $primeSquared.route {
          Square(value: $potentialPrime)
        }
      }
    }

    private func isPrime(_ num: Int) -> Bool {
      guard num >= 2 else {
        return false
      }
      guard num != 2 else {
        return true
      }
      guard num % 2 != 0 else {
        return false
      }
      return !stride(
        from: 3,
        through: Int(sqrt(Double(num))),
        by: 2
      ).contains { num % $0 == 0 }
    }

  }

}
