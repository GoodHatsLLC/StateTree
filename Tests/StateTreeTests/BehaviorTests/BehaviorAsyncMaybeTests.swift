import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - BehaviorAsyncMaybeTests

final class BehaviorAsyncMaybeTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_cancel_firesSynchronously_onTreeActor() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    life
      .stage(on: stage)
    var alwaysDidCancel = false
    // Trigger the behavior creation — scoped to the subnode.
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    // Trigger the behavior on a subnode, not the root.
    let subnodeResolution = subnode
      .$scope
      .run(.id("always")) {
        // A single yield should suffice.
        await Task.yield()
        return 123
      }
      .onResult { _ in
        XCTFail()
      } onCancel: {
        alwaysDidCancel = true
      }
    // The disposal is synchronous across node boundaries.
    life.dispose()
    // The lifetime object stores the resolution info.
    let resolutions = await life.awaitBehaviors()
    XCTAssert(alwaysDidCancel)
    XCTAssertEqual(1, resolutions.count)
    XCTAssert(resolutions.contains {
      $0.state == .cancelled && $0.id == .id("always")
    })
    // The resolution returned when making the behavior
    // is also queryable.
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("always"))
    XCTAssertEqual(resolved.state, .cancelled)
  }

  @TreeActor
  func test_success() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    struct TestError: Error { }
    life
      .stage(on: stage)
    let shouldError = false
    var didSucceed = false
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    let subnodeResolution = subnode
      .$scope
      .run(.id("test_success")) {
        if shouldError {
          XCTFail("test setup issue")
          throw TestError()
        } else {
          return 234_124
        }
      }
      .onResult { result in
        guard case .success(let value) = result
        else {
          XCTFail()
          return
        }
        XCTAssertEqual(234_124, value)
        didSucceed = true
      } onCancel: {
        XCTFail()
      }

    let resolutions = await life.awaitBehaviors()
    XCTAssert(didSucceed)
    XCTAssertEqual(1, resolutions.count)
    XCTAssert(resolutions.contains {
      $0.state == .finished && $0.id == .id("test_success")
    })
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("test_success"))
    XCTAssertEqual(resolved.state, .finished)
  }

  @TreeActor
  func test_failure() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    struct TestError: Error { }
    life
      .stage(on: stage)
    let shouldError = true
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    let subnodeResolution = subnode
      .$scope
      .run(.id("test_failure")) {
        if shouldError {
          throw TestError()
        } else {
          XCTFail("test setup issue")
          return 234_124
        }
      }
      .onResult { result in
        guard
          case .failure(let error) = result,
          error is TestError
        else {
          XCTFail()
          return
        }
      } onCancel: {
        XCTFail()
      }
    let resolutions = await life.awaitBehaviors()
    XCTAssertEqual(1, resolutions.count)
    XCTAssert(resolutions.contains {
      $0.state == .failed && $0.id == .id("test_failure")
    })
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("test_failure"))
    XCTAssertEqual(resolved.state, .failed)
  }

}

// MARK: BehaviorAsyncMaybeTests.ScopeNode

extension BehaviorAsyncMaybeTests {

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
