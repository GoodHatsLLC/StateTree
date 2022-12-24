import XCTest

@testable import Utilities

@MainActor
final class TestDebugSystemUptimeOverrideTests: XCTestCase {

  func test_incrementingDateMillisecondsOverride() {
    let times = Array(repeating: -1, count: 100)
      .map { _ in Uptime.systemUptime }

    let handle = Uptime.debug_overrideUptime(incrementingFrom: 2)

    let overrideResults = Array(repeating: -1, count: 100)
      .map { _ in Uptime.systemUptime }

    let expected: [TimeInterval] = Array(2..<102)
      .map { (val: Int) in TimeInterval(val) }

    XCTAssertEqual(overrideResults, expected)
    XCTAssertNotEqual(times, expected)

    handle.dispose()
  }

}
