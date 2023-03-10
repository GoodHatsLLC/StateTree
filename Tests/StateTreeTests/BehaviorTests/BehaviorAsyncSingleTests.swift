import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - BehaviorAsyncSingleTests

final class BehaviorAsyncSingleTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func _test_cancel_firesSynchronously_onTreeActor() async throws {
    // behaviors use an internal actor, but cancellation can also
    // be triggered by the host node being disposed. This should
    // always happen synchronously and prevent later emissions.

    let life = try Tree.main
      .start(root: RootNode())
    life
      .stage(on: stage)
    var alwaysDidCancel = false
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    let subnodeResolution = subnode
      .$scope
      .run(.id("sync_cancel")) {
        // A single yield should suffice.
        await Task.yield()
        return 123
      }
      .onSuccess { _ in
        XCTFail()
      } onCancel: {
        alwaysDidCancel = true
      }
    // This is called after the yielded .value closure
    // but is then synchronous, even across node boundaries.
    life.dispose()
    // The lifetime object stores the resolution info.
    let resolutions = await life.awaitBehaviors()
    XCTAssert(alwaysDidCancel)
    XCTAssertEqual(1, resolutions.count)
    XCTAssert(resolutions.contains {
      $0.state == .cancelled && $0.id == .id("sync_cancel")
    })
    // The resolution returned when making the behavior
    // is also queryable.
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("sync_cancel"))
    XCTAssertEqual(resolved.state, .cancelled)
  }

  @TreeActor
  func test_onSuccess() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    life
      .stage(on: stage)
    var didSucceed = false
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    let subnodeResolution = subnode
      .$scope
      .run(.id("test_success")) {
        await Task {
          await Task.yield()
          return 123_321
        }.value
      }
      .onSuccess { value in
        XCTAssertEqual(value, 123_321)
        didSucceed = true
      } onCancel: {
        XCTFail()
      }

    // The lifetime object stores the resolution info
    // allowing us to await completion.
    let resolutions = await life.awaitBehaviors()
    XCTAssert(didSucceed)
    XCTAssertEqual(1, resolutions.count)
    XCTAssert(resolutions.contains {
      $0.state == .finished && $0.id == .id("test_success")
    })
    // The resolution returned when making the behavior
    // is also queryable.
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("test_success"))
    XCTAssertEqual(resolved.state, .finished)
  }

  @TreeActor
  func test_value_success() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    life
      .stage(on: stage)
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    let value = await subnode
      .$scope
      .run {
        123_444
      }
      .value
    XCTAssertEqual(value, 123_444)
  }

  @TreeActor
  func test_value_cancel_nil() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    life
      .stage(on: stage)
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    let value = AsyncValue<Int>()
    Task {
      life.dispose()
    }
    let nilAsCancelled = await subnode
      .$scope
      .run {
        await value.value
      }
      .value
    XCTAssertNil(
      nilAsCancelled,
      ".value should return nil if its behavior is disposed."
    )
  }

  @TreeActor
  func test_get_success() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    life
      .stage(on: stage)
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    let value = try await subnode
      .$scope
      .run { () throws -> Int in
        123_555
      }
      .get()
    XCTAssertEqual(
      value, 123_555,
      "the success value should be passed through to get()"
    )
  }

  @TreeActor
  func test_get_throwingCancel() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    life
      .stage(on: stage)
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    let value = AsyncValue<Int>()
    Task {
      life.dispose()
    }
    var didCancel = false
    do {
      _ = try await subnode
        .$scope
        .run {
          await value.value
        }
        .get()
      XCTFail("this should be unreached due to the throw")
    } catch is BehaviorCancellationError {
      didCancel = true
    } catch {
      XCTFail("the thrown exception should be a BehaviorCancellationError")
    }
    await life.awaitBehaviors()

    XCTAssert(didCancel)
  }
}

// MARK: BehaviorAsyncSingleTests.ScopeNode

extension BehaviorAsyncSingleTests {

  struct RootNode: Node {
    @Route(ScopeNode.self) var scopedNode
    var rules: some Rules {
      $scopedNode.route(
        to: ScopeNode()
      )
    }
  }

  // MARK: - ScopeNode

  struct ScopeNode: Node {
    @Scope var scope
    var rules: some Rules {
      .none
    }
  }
}
