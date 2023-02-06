import Combine
import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - BehaviorCancelTests

@TreeActor
final class BehaviorCancelTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { XCTAssertNil(Tree.main._info) }
  override func tearDown() {
    stage.reset()
    XCTAssertNil(Tree.main._info)
  }

  func test_cancel_alwaysBehavior() async throws {
    let life = try Tree.main.start(root: ScopeNode())
    life.stage(on: stage)
    let waitTime: UInt64 = NSEC_PER_SEC

    var alwaysDidCancel = false
    life.rootNode.always(
      id: .id("always"),
      wait: waitTime,
      value: 123,
      valueCallback: { _ in
        XCTFail()
      },
      cancelCallback: {
        alwaysDidCancel = true
      }
    )
    Task {
      await Task.yield()
      life.dispose()
    }
    let resolutions = await life.resolvedBehaviors()
    XCTAssert(alwaysDidCancel)
    XCTAssertEqual(1, resolutions.count)
    XCTAssert(resolutions.contains {
      $0.resolution == .cancelled && $0.id == .id("always")
    })
  }

  func test_cancel_maybeBehavior() async throws {
    let life = try Tree.main.start(root: ScopeNode())
    life.stage(on: stage)
    let waitTime: UInt64 = NSEC_PER_SEC
    var maybeDidCancel = false
    life.rootNode.maybe(
      id: .id("maybe"),
      wait: waitTime,
      value: "SOME_VALUE",
      valueCallback: { _ in
        XCTFail()
      },
      cancelCallback: {
        maybeDidCancel = true
      }
    )
    Task {
      await Task.yield()
      life.dispose()
    }
    let resolutions = await life.resolvedBehaviors()
    XCTAssert(maybeDidCancel)
    XCTAssertEqual(1, resolutions.count)
    XCTAssert(resolutions.contains {
      $0.resolution == .cancelled && $0.id == .id("maybe")
    })
  }

  func test_cancel_subscriptionBehavior() async throws {
    let life = try Tree.main.start(root: ScopeNode())
    life.stage(on: stage)
    let waitTime: UInt64 = NSEC_PER_SEC
    var subscriptionDidCancel = false
    life.rootNode.subscription(
      id: .id("subscription"),
      wait: waitTime,
      values: [1, 2, 3, 4, 5],
      valueCallback: { _ in
        XCTFail()
      },
      finishedCallback: {
        XCTFail()
      },
      cancelCallback: {
        subscriptionDidCancel = true
      },
      failureCallback: { _ in
        XCTFail()
      }
    )
    Task {
      await Task.yield()
      life.dispose()
    }
    let resolutions = await life.resolvedBehaviors()
    XCTAssert(subscriptionDidCancel)
    XCTAssertEqual(1, resolutions.count)
    XCTAssert(resolutions.contains {
      $0.resolution == .cancelled && $0.id == .id("subscription")
    })
  }

  /// FIXME: this is occasionally flaky
  func test_cancel_multipleBehaviors() async throws {
    let life = try Tree.main.start(root: ScopeNode())
    life.stage(on: stage)
    let waitTime: UInt64 = NSEC_PER_SEC

    var alwaysDidCancel = false
    life.rootNode.always(
      id: .id("always"),
      wait: waitTime,
      value: 123,
      valueCallback: { _ in
        XCTFail()
      },
      cancelCallback: {
        alwaysDidCancel = true
      }
    )

    var maybeDidCancel = false
    life.rootNode.maybe(
      id: .id("maybe"),
      wait: waitTime,
      value: "SOME_VALUE",
      valueCallback: { _ in
        XCTFail()
      },
      cancelCallback: {
        maybeDidCancel = true
      }
    )

    var subscriptionDidCancel = false
    life.rootNode.subscription(
      id: .id("subscription"),
      wait: waitTime,
      values: [1, 2, 3, 4, 5],
      valueCallback: { _ in
        XCTFail()
      },
      finishedCallback: {
        XCTFail()
      },
      cancelCallback: {
        subscriptionDidCancel = true
      },
      failureCallback: { _ in
        XCTFail()
      }
    )

    Task {
      await Task.yield()
      life.dispose()
    }
    let resolutions = await life.resolvedBehaviors()

    XCTAssert(alwaysDidCancel)
    XCTAssert(maybeDidCancel)
    XCTAssert(subscriptionDidCancel)

    XCTAssertEqual(3, resolutions.count)

    XCTAssert(resolutions.contains {
      $0.resolution == .cancelled && $0.id == .id("always")
    })
    XCTAssert(resolutions.contains {
      $0.resolution == .cancelled && $0.id == .id("maybe")
    })
    XCTAssert(resolutions.contains {
      $0.resolution == .cancelled && $0.id == .id("subscription")
    })
  }
}

// MARK: BehaviorCancelTests.ScopeNode

extension BehaviorCancelTests {

  // MARK: - ScopeNode

  struct ScopeNode: Node {

    @Scope var scope

    var rules: some Rules {
      .none
    }

    func maybe<T: Equatable>(
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
      wait: UInt64,
      values: [T],
      valueCallback: @escaping (_ value: T) -> Void,
      finishedCallback: @escaping () -> Void,
      cancelCallback: @escaping () -> Void,
      failureCallback: @escaping (any Error) -> Void
    ) {
      $scope.run(id) {
        values
          .publisher
          .delay(for: .nanoseconds(Int(wait)), scheduler: RunLoop.main)
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
