import Combine
import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - BehaviorInterceptionTests

@TreeActor
final class BehaviorInterceptionTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { XCTAssertNil(Tree.main._info) }
  override func tearDown() {
    stage.reset()
  }

  func test_intercept_alwaysBehavior() async throws {
    let originalValue = "ORIGINAL VALUE"
    let substituteValue = "SUBSTITUTE VALUE"
    let id: BehaviorID = .id("always")

    let life = try Tree.main
      .start(
        root: ScopeNode(),
        configuration: .init(
          behaviorHost: .init(
            tracking: .track,
            behaviorInterceptors: [
              BehaviorInterceptor(id: id, type: AsyncValueBehavior<Void, String>.self, action: {
                substituteValue
              }),
              BehaviorInterceptor(
                id: .id("other"),
                type: AsyncValueBehavior<Void, String>.self,
                action: {
                  "some other value"
                }
              ),
            ]
          )
        )
      )
    life.stage(on: stage)

    var actionCount = 0

    life.rootNode.always(
      id: id,
      wait: 0,
      value: originalValue,
      valueCallback: {
        XCTAssertEqual(substituteValue, $0)
        actionCount += 1
      },
      cancelCallback: {
        XCTFail()
      }
    )
    _ = await life.resolvedBehaviors()

    XCTAssertEqual(1, actionCount)
  }

  func test_intercept_maybeBehavior() async throws {
    let originalValue = "ORIGINAL VALUE"
    let substituteValue = "SUBSTITUTE VALUE"
    let id: BehaviorID = .id("maybe")

    let life = try Tree.main
      .start(
        root: ScopeNode(),
        configuration: .init(
          behaviorHost: .init(
            tracking: .track,
            behaviorInterceptors: [
              BehaviorInterceptor(id: id, type: AsyncThrowingBehavior<Void, String>.self, action: {
                substituteValue
              }),
              BehaviorInterceptor(
                id: .id("other"),
                type: AsyncThrowingBehavior<Void, String>.self,
                action: {
                  "other value"
                }
              ),
            ]
          )
        )
      )
    life.stage(on: stage)

    var actionCount = 0

    life.rootNode.maybe(
      id: id,
      wait: 0,
      value: originalValue,
      resultCallback: { result in
        XCTAssertEqual(substituteValue, try? result.get())
        actionCount += 1
      },
      cancelCallback: {
        XCTFail()
      }
    )
    _ = await life.resolvedBehaviors()

    XCTAssertEqual(1, actionCount)
  }

  func test_intercept_sequenceBehavior() async throws {
    let originalValues = [1, 2, 3, 4, 5]
    let substituteValues = [101, 102, 103]
    let id: BehaviorID = .id("sequence")

    let life = try Tree.main
      .start(
        root: ScopeNode(),
        configuration: .init(
          behaviorHost: .init(
            tracking: .track,
            behaviorInterceptors: [
              BehaviorInterceptor(
                id: id,
                type: AsyncSequenceBehavior<Void, Int>.self,
                action: {
                  .init(
                    substituteValues
                      .publisher
                      .receive(on: DispatchQueue.global())
                      .values
                  )
                }
              ),
              BehaviorInterceptor(
                id: .id("other"),
                type: AsyncThrowingBehavior<Void, String>.self,
                action: {
                  "other value"
                }
              ),
            ]
          )
        )
      )

    life.stage(on: stage)

    var remaining = substituteValues
    var didFinish = false
    life.rootNode.sequence(id: id, values: originalValues.publisher.values) { value in
      XCTAssert(remaining.contains(value))
      XCTAssertFalse(originalValues.contains(value))
      remaining.removeAll(where: { $0 == value })
    } finishedCallback: {
      didFinish = true
    } cancelCallback: {
      XCTFail()
    } failureCallback: { _ in
      XCTFail()
    }
    _ = await life.resolvedBehaviors()

    XCTAssert(remaining.isEmpty)
    XCTAssert(didFinish)
  }
}

// MARK: BehaviorInterceptionTests.ScopeNode

extension BehaviorInterceptionTests {

  // MARK: - ScopeNode

  struct ScopeNode: Node {

    @Scope var scope

    var rules: some Rules {
      .none
    }

    func maybe<T>(
      id: BehaviorID,
      wait: UInt64,
      value: T,
      resultCallback: @escaping (_ result: Result<T, Error>) -> Void,
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
        resultCallback(result)
      } onCancel: {
        cancelCallback()
      }
    }

    func always<T>(
      id: BehaviorID,
      wait: UInt64,
      value: T,
      valueCallback: @escaping (_ value: T) -> Void,
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

    func sequence<T>(
      id: BehaviorID,
      values: AsyncPublisher<T>,
      valueCallback: @escaping (_ value: T.Output) -> Void,
      finishedCallback: @escaping () -> Void,
      cancelCallback: @escaping () -> Void,
      failureCallback: @escaping (any Error) -> Void
    ) {
      $scope.run(id) {
        values
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
