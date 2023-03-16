import Behaviors
import Disposable
import Emitter
import TreeActor
import XCTest

// MARK: - BehaviorThrowingTests

final class BehaviorThrowingTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  func test_success() async throws {
    let shouldError = false
    var didSucceed = false
    let res = await Behaviors.make(.id("test_success")) { () throws -> Int in
      if shouldError {
        XCTFail("test setup issue")
        throw TestError()
      } else {
        234_124
      }
    }
    .scoped(to: stage, manager: .init())
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
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_success"))
    XCTAssertEqual(resolved.state, .finished)
    XCTAssert(didSucceed)
  }

  func test_failure() async throws {
    let shouldError = true
    var didFail = false
    let res = await Behaviors.make(.id("test_failure")) { () throws -> Int in
      if shouldError {
        throw TestError()
      } else {
        XCTFail("test setup issue")
        return 234_124
      }
    }
    .scoped(to: stage, manager: .init())
    .onResult { result in
      guard
        case .failure(let error) = result,
        error is TestError
      else {
        XCTFail()
        return
      }
      didFail = true
    } onCancel: {
      XCTFail()
    }
    let resolved = await res.value
    XCTAssertEqual(resolved.id, .id("test_failure"))
    XCTAssertEqual(resolved.state, .failed)
    XCTAssert(didFail)
  }

}
