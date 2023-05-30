import Disposable
@_spi(Implementation) import StateTree
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
    try tree.start()
      .autostop()
      .stage(on: stage)
    XCTAssertNil(try tree.assume.rootNode.subRoute)
    let initialState = try tree.assume.snapshot()
    // print("INITIAL")
    // dump(initialState)
    try tree.assume.rootNode.routeIfNegative = -2
    try tree.assume.rootNode.subRoute?.subValue = 123
    let laterState = try tree.assume.snapshot()
    // print("LATER")
    // dump(laterState)
    XCTAssertEqual(try tree.assume.rootNode.routeIfNegative, -2)
    XCTAssertEqual(try tree.assume.rootNode.subRoute?.value, -2)
    XCTAssertEqual(try tree.assume.rootNode.subRoute?.subValue, 123)
    XCTAssertNotNil(try tree.assume.rootNode.subRoute)
    stage.reset()

    let restartTree = Tree(
      root: RootNode()
    )
    try restartTree.start(from: laterState)
      .autostop()
      .stage(on: stage)

    let replayedState = try restartTree.assume.snapshot()
    // print("REPLAYED")
    // dump(replayedState)
    XCTAssertEqual(try restartTree.assume.rootNode.routeIfNegative, -2)
    XCTAssertNotNil(try restartTree.assume.rootNode.subRoute)
    XCTAssertEqual(try restartTree.assume.rootNode.subRoute?.value, -2)
    XCTAssertEqual(try restartTree.assume.rootNode.subRoute?.subValue, 123)
    XCTAssertEqual(replayedState.formattedJSON, laterState.formattedJSON)
    XCTAssertNotEqual(replayedState.formattedJSON, initialState.formattedJSON)
    stage.reset()
  }

  @TreeActor
  func test_setState() async throws {
    let tree = Tree(
      root: RootNode()
    )
    try tree.start()

    let initialState = try tree.assume.snapshot()

    try tree.assume.rootNode.routeIfNegative = -2
    try tree.assume.rootNode.subRoute?.subValue = 2
    let laterState = try tree.assume.snapshot()
    XCTAssert(try tree.assume.info.isConsistent == true)

    try tree.assume.rootNode.routeIfNegative = -3
    let finalState = try tree.assume.snapshot()

    try tree.assume.restore(state: initialState)
    XCTAssert(try tree.assume.info.isConsistent == true)
    XCTAssertEqual(try tree.assume.rootNode.routeIfNegative, 0)
    XCTAssertNil(try tree.assume.rootNode.subRoute)

    try tree.assume.restore(state: laterState)
    XCTAssert(try tree.assume.info.isConsistent == true)
    XCTAssertEqual(try tree.assume.rootNode.routeIfNegative, -2)
    XCTAssertEqual(try tree.assume.rootNode.subRoute?.subValue, 2)
    XCTAssertEqual(try tree.assume.rootNode.subRoute?.subSubRoute?.value, -2)

    let recapture = try tree.assume.snapshot()
    XCTAssertEqual(laterState.formattedJSON, recapture.formattedJSON)
    XCTAssert(try tree.assume.info.isConsistent == true)

    try tree.assume.rootNode.routeIfNegative = -3
    let finalRecapture = try tree.assume.snapshot()

    XCTAssertEqual(finalState.formattedJSON, finalRecapture.formattedJSON)
    stage.reset()
  }

  @TreeActor
  func test_setState_thrash() async throws {
    let tree = Tree(
      root: PrimeSquare()
    )
    try tree.start()
      .autostop()
      .stage(on: stage)
    XCTAssertEqual(try tree.assume.rootNode.primeSquared?.square, nil)
    let snap0 = try tree.assume.snapshot()
    XCTAssertEqual(try tree.assume.info.nodeCount, 1)

    try tree.assume.rootNode.potentialPrime = 2
    XCTAssertEqual(try tree.assume.rootNode.primeSquared?.square, 4)
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)
    let snap1 = try tree.assume.snapshot()

    try tree.assume.rootNode.potentialPrime = 4
    XCTAssertEqual(try tree.assume.rootNode.primeSquared?.square, nil)
    let snap2 = try tree.assume.snapshot()
    XCTAssertEqual(try tree.assume.info.nodeCount, 1)

    try tree.assume.rootNode.potentialPrime = 7
    XCTAssertEqual(try tree.assume.rootNode.primeSquared?.square, 49)
    let snap3 = try tree.assume.snapshot()
    XCTAssertEqual(try tree.assume.info.nodeCount, 2)

    stage.reset()
    await tree.once.behaviorsFinished()

    let tree2 = Tree(
      root: PrimeSquare()
    )
    try tree2.start(from: snap3)
      .autostop()
      .stage(on: stage)

    XCTAssertEqual(try tree2.assume.rootNode.primeSquared?.square, 49)
    XCTAssertEqual(try tree2.assume.info.nodeCount, 2)

    try tree2.assume.restore(state: snap0)
    XCTAssert(try tree2.assume.info.isConsistent == true)
    XCTAssertEqual(try tree2.assume.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(try tree2.assume.info.nodeCount, 1)

    try tree2.assume.restore(state: snap1)
    XCTAssert(try tree2.assume.info.isConsistent == true)
    XCTAssertEqual(try tree2.assume.rootNode.primeSquared?.square, 4)
    XCTAssertEqual(try tree2.assume.info.nodeCount, 2)

    try tree2.assume.restore(state: snap0)
    XCTAssert(try tree2.assume.info.isConsistent == true)
    XCTAssertEqual(try tree2.assume.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(try tree2.assume.info.nodeCount, 1)

    try tree2.assume.restore(state: snap3)
    XCTAssert(try tree2.assume.info.isConsistent == true)
    XCTAssertEqual(try tree2.assume.rootNode.primeSquared?.square, 49)
    XCTAssertEqual(try tree2.assume.info.nodeCount, 2)

    try tree2.assume.restore(state: snap2)
    XCTAssert(try tree2.assume.info.isConsistent == true)
    XCTAssertEqual(try tree2.assume.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(try tree2.assume.info.nodeCount, 1)

    stage.reset()
  }

}

extension PlaybackTests {

  // MARK: - Square

  struct SubSubNode: Node {
    @Projection var value: Int
    var rules: some Rules { .none }
  }

  struct SubNode: Node {

    @Route var subSubRoute: SubSubNode? = nil
    @Value var subValue = 32
    @Projection var value: Int

    var rules: some Rules {
      if subValue == 2 {
        Attach($subSubRoute, to: SubSubNode(value: $value))
      }
    }
  }

  // MARK: - RootNode

  struct RootNode: Node {

    @Value var routeIfNegative = 0
    @Route var subRoute: SubNode? = nil

    var rules: some Rules {
      if routeIfNegative < 0 {
        Attach(
          $subRoute,
          to:
          SubNode(value: $routeIfNegative)
        )
      }
    }
  }

  // MARK: - Square

  struct Square: Node {

    @Value var square: Int!
    @Projection var value: Int

    var rules: some Rules {
      OnUpdate(value) { value in
        square = value * value
      }
    }
  }

  // MARK: - PrimeSquare

  struct PrimeSquare: Node {

    // MARK: Internal

    @Value var potentialPrime = 0
    @Route var primeSquared: Square? = nil

    var rules: some Rules {
      if isPrime(potentialPrime) {
        Attach(
          $primeSquared,
          to:
          Square(value: $potentialPrime)
        )
      }
    }

    // MARK: Private

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
