import Utilities
import XCTest

final class AsyncTimeoutTests: XCTestCase {
  func testTimeout() async throws {
    let never = Async.Value<Int>()
    let result = await Async.timeout(seconds: 0.1) {
      await never.value
    }
    XCTAssertThrowsError(try result.get())
  }

  func testValue() async throws {
    let intSignal = Async.Value<Int>()
    Task {
      await Task.yield()
      await intSignal.resolve(to: 1)
    }
    let result = await Async.timeout(seconds: 1) {
      await intSignal.value
    }

    let value = try result.get()
    XCTAssertEqual(value, 1)
  }
}
