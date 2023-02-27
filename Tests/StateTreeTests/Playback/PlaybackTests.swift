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
    let handle = try Tree.main
      .start(
        root: RootNode()
      )
    handle.stage(on: stage)
    XCTAssertNil(handle.rootNode.subRoute)
    let initialState = handle.snapshot()
    // print("INITIAL")
    // dump(initialState)
    handle.rootNode.routeIfNegative = -2
    handle.rootNode.subRoute?.subValue = 123
    let laterState = handle.snapshot()
    // print("LATER")
    // dump(laterState)
    XCTAssertEqual(handle.rootNode.routeIfNegative, -2)
    XCTAssertEqual(handle.rootNode.subRoute?.value, -2)
    XCTAssertEqual(handle.rootNode.subRoute?.subValue, 123)
    XCTAssertNotNil(handle.rootNode.subRoute)
    handle.dispose()

    let restartHandle = try Tree.main.start(
      root: RootNode(),
      from: laterState
    )
    handle.stage(on: stage)

    let replayedState = restartHandle.snapshot()
    // print("REPLAYED")
    // dump(replayedState)
    XCTAssertEqual(restartHandle.rootNode.routeIfNegative, -2)
    XCTAssertNotNil(restartHandle.rootNode.subRoute)
    XCTAssertEqual(restartHandle.rootNode.subRoute?.value, -2)
    XCTAssertEqual(restartHandle.rootNode.subRoute?.subValue, 123)
    XCTAssertEqual(replayedState, laterState)
    XCTAssertNotEqual(replayedState, initialState)
    restartHandle.dispose()
  }

  @TreeActor
  func test_setState() async throws {
    let handle = try Tree.main
      .start(
        root: RootNode()
      )
    handle.stage(on: stage)

    let initialState = handle.snapshot()

    handle.rootNode.routeIfNegative = -2
    handle.rootNode.subRoute?.subValue = 2
    let laterState = handle.snapshot()
    XCTAssert(Tree.main._info?.isConsistent == true)

    handle.rootNode.routeIfNegative = -3
    let finalState = handle.snapshot()

    try handle.set(state: initialState)
    XCTAssert(Tree.main._info?.isConsistent == true)
    XCTAssertEqual(handle.rootNode.routeIfNegative, 0)
    XCTAssertNil(handle.rootNode.subRoute)

    try handle.set(state: laterState)
    XCTAssert(Tree.main._info?.isConsistent == true)
    XCTAssertEqual(handle.rootNode.routeIfNegative, -2)
    XCTAssertEqual(handle.rootNode.subRoute?.subValue, 2)
    XCTAssertEqual(handle.rootNode.subRoute?.subSubRoute?.value, -2)

    let recapture = handle.snapshot()
    XCTAssertEqual(laterState, recapture)

    handle.rootNode.routeIfNegative = -3
    let finalRecapture = handle.snapshot()

    XCTAssertEqual(finalState, finalRecapture)
    handle.dispose()
  }

  @TreeActor
  func test_setState_thrash() async throws {
    let lifetime = try Tree.main
      .start(
        root: PrimeSquare()
      )
    lifetime.stage(on: stage)
    XCTAssertEqual(lifetime.rootNode.primeSquared?.square, nil)
    let snap0 = lifetime.snapshot()
    XCTAssertEqual(Tree.main._info?.nodeCount, 1)

    lifetime.rootNode.potentialPrime = 2
    XCTAssertEqual(lifetime.rootNode.primeSquared?.square, 4)
    XCTAssertEqual(Tree.main._info?.nodeCount, 2)
    let snap1 = lifetime.snapshot()

    lifetime.rootNode.potentialPrime = 4
    XCTAssertEqual(lifetime.rootNode.primeSquared?.square, nil)
    let snap2 = lifetime.snapshot()
    XCTAssertEqual(Tree.main._info?.nodeCount, 1)

    lifetime.rootNode.potentialPrime = 7
    XCTAssertEqual(lifetime.rootNode.primeSquared?.square, 49)
    let snap3 = lifetime.snapshot()
    XCTAssertEqual(Tree.main._info?.nodeCount, 2)

    lifetime.dispose()
    XCTAssertEqual(lifetime.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(Tree.main._info?.nodeCount ?? 0, 0)

    let lifetime2 = try Tree.main
      .start(
        root: PrimeSquare(),
        from: snap3
      )
    lifetime2.stage(on: stage)

    XCTAssertEqual(lifetime2.rootNode.primeSquared?.square, 49)
    XCTAssertEqual(Tree.main._info?.nodeCount, 2)

    try lifetime2.set(state: snap0)
    XCTAssert(Tree.main._info?.isConsistent == true)
    XCTAssertEqual(lifetime.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(Tree.main._info?.nodeCount, 1)

    try lifetime2.set(state: snap1)
    XCTAssert(Tree.main._info?.isConsistent == true)
    XCTAssertEqual(lifetime2.rootNode.primeSquared?.square, 4)
    XCTAssertEqual(Tree.main._info?.nodeCount, 2)

    try lifetime2.set(state: snap0)
    XCTAssert(Tree.main._info?.isConsistent == true)
    XCTAssertEqual(lifetime2.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(Tree.main._info?.nodeCount, 1)

    try lifetime2.set(state: snap3)
    XCTAssert(Tree.main._info?.isConsistent == true)
    XCTAssertEqual(lifetime2.rootNode.primeSquared?.square, 49)
    XCTAssertEqual(Tree.main._info?.nodeCount, 2)

    try lifetime2.set(state: snap2)
    XCTAssert(Tree.main._info?.isConsistent == true)
    XCTAssertEqual(lifetime2.rootNode.primeSquared?.square, nil)
    XCTAssertEqual(Tree.main._info?.nodeCount, 1)

    lifetime2.dispose()
    XCTAssertFalse(Tree.main._info?.isActive ?? false)
    XCTAssertEqual(lifetime2.rootNode.primeSquared?.square, nil)
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
