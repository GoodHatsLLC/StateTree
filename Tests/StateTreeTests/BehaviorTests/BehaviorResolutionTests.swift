import Combine
import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - BehaviorResolutionTests

@TreeActor
final class BehaviorResolutionTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { XCTAssertNil(Tree.main._info) }
  override func tearDown() {
    stage.reset()
  }

  func test_await_alwaysBehavior() async throws {
    let life = try Tree.main.start(root: ScopeNode())
    life.stage(on: stage)
    let waitTime: UInt64 = (NSEC_PER_SEC / 2)
    var alwaysCount = 0
    life.rootNode.always(
      id: .id("always"),
      wait: waitTime,
      value: 123,
      valueCallback: {
        XCTAssertEqual(123, $0)
        alwaysCount += 1
      },
      cancelCallback: {
        XCTFail()
      }
    )
    let resolutions = await life.resolvedBehaviors()
    XCTAssertEqual(1, alwaysCount)
    XCTAssertEqual(resolutions.count, 1)
    XCTAssert(resolutions.contains {
      $0.resolution == .finished && $0.id == .id("always")
    })
  }

  func test_await_maybeBehavior() async throws {
    let life = try Tree.main.start(root: ScopeNode())
    life.stage(on: stage)
    let waitTime: UInt64 = (NSEC_PER_SEC / 2)
    var maybeCount = 0
    life.rootNode.maybe(
      id: .id("maybe"),
      wait: waitTime,
      value: "SOME_VALUE",
      valueCallback: {
        XCTAssertEqual("SOME_VALUE", $0)
        maybeCount += 1
      },
      cancelCallback: {
        XCTFail()
      }
    )
    let resolutions = await life.resolvedBehaviors()
    XCTAssertEqual(1, maybeCount)
    XCTAssertEqual(1, resolutions.count)
    XCTAssert(resolutions.contains {
      $0.resolution == .finished && $0.id == .id("maybe")
    })
  }

  /// FIXME: flake
  func test_await_subscriptionBehavior() async throws {
    let life = try Tree.main.start(root: ScopeNode())
    life.stage(on: stage)
    let waitTime: UInt64 = (NSEC_PER_SEC / 2)
    var subscriptionCount = 0
    var values = [1, 2, 3, 4, 5]
    let vInput = values
    var didFinish = false
    life.rootNode.subscription(
      id: .id("subscription"),
      wait: waitTime,
      values: vInput,
      valueCallback: { value in
        XCTAssert(values.contains(value))
        values.removeAll { $0 == value }
        subscriptionCount += 1
      },
      finishedCallback: {
        didFinish = true
      },
      cancelCallback: {
        XCTFail()
      },
      failureCallback: { _ in
        XCTFail()
      }
    )
    let resolutions = await life.resolvedBehaviors()
    XCTAssertEqual(5, subscriptionCount)
    XCTAssert(didFinish)
    XCTAssertEqual(resolutions.count, 1)
    XCTAssert(resolutions.contains {
      $0.resolution == .finished && $0.id == .id("subscription")
    })
  }

  func test_await_multipleBehaviors() async throws {
    let life = try Tree.main.start(root: ScopeNode())
    life.stage(on: stage)
    let waitTime: UInt64 = (NSEC_PER_SEC / 2)
    var alwaysCount = 0
    life.rootNode.always(
      id: .id("always"),
      wait: waitTime,
      value: 123,
      valueCallback: {
        XCTAssertEqual(123, $0)
        alwaysCount += 1
      },
      cancelCallback: {
        XCTFail()
      }
    )

    var maybeCount = 0
    life.rootNode.maybe(
      id: .id("maybe"),
      wait: waitTime,
      value: "SOME_VALUE",
      valueCallback: {
        XCTAssertEqual("SOME_VALUE", $0)
        maybeCount += 1
      },
      cancelCallback: {
        XCTFail()
      }
    )

    var subscriptionCount = 0
    var values = [1, 2, 3, 4, 5]
    let vInput = values
    var didFinish = false
    life.rootNode.subscription(
      id: .id("subscription"),
      wait: waitTime,
      values: vInput,
      valueCallback: {
        XCTAssertEqual(values.removeFirst(), $0)
        subscriptionCount += 1
      },
      finishedCallback: {
        didFinish = true
      },
      cancelCallback: {
        XCTFail()
      },
      failureCallback: { _ in
        XCTFail()
      }
    )
    let resolutions = await life.resolvedBehaviors()

    XCTAssertEqual(1, alwaysCount)
    XCTAssertEqual(1, maybeCount)
    XCTAssertEqual(5, subscriptionCount)
    XCTAssert(didFinish)
    XCTAssertEqual(resolutions.count, 3)
    XCTAssert(resolutions.contains {
      $0.resolution == .finished && $0.id == .id("always")
    })
    XCTAssert(resolutions.contains {
      $0.resolution == .finished && $0.id == .id("maybe")
    })
    XCTAssert(resolutions.contains {
      $0.resolution == .finished && $0.id == .id("subscription")
    })
  }
}

// MARK: BehaviorResolutionTests.ScopeNode

extension BehaviorResolutionTests {

  // MARK: - ScopeNode

  struct ScopeNode: Node {

    @Scope var scope

    var rules: some Rules {
      .none
    }

    func maybe<T: Equatable & Sendable>(
      id: BehaviorID,
      wait: UInt64,
      value: T,
      valueCallback: @escaping (_ value: T?) -> Void,
      cancelCallback: @escaping () -> Void
    ) {
      $scope.run(id) {
        _ = await Task {
          try? await Task.sleep(nanoseconds: wait)
        }.result
        return try await Task<T, Error> {
          value
        }.value
      }.onCompletion { result in
        valueCallback(try? result.get())
      } onCancel: {
        cancelCallback()
      }
    }

    func always<T: Equatable>(
      id: BehaviorID,
      wait: UInt64,
      value: T,
      valueCallback: @escaping (_ value: T?) -> Void,
      cancelCallback: @escaping () -> Void
    ) {
      $scope.run(id) {
        _ = await Task {
          try? await Task.sleep(nanoseconds: wait)
        }.result
        return value
      }
      .onFinish { value in
        valueCallback(value)
      } onCancel: {
        cancelCallback()
      }
    }

    func subscription<T: Equatable>(
      id: BehaviorID,
      wait _: UInt64,
      values: [T],
      valueCallback: @escaping (_ value: T) -> Void,
      finishedCallback: @escaping () -> Void,
      cancelCallback: @escaping () -> Void,
      failureCallback: @escaping (any Error) -> Void
    ) {
      $scope.run(id) {
        values
          .publisher
          .receive(on: DispatchQueue.global())
          .values
      }
      .onValue { value in
        valueCallback(value)
      } onFinish: {
        finishedCallback()
      } onCancel: {
        cancelCallback()
      } onFailure: { err in
        failureCallback(err)
      }
    }

  }
}
