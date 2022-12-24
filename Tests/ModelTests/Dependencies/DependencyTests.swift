import Disposable
import Emitter
import Foundation
import Node
import SourceLocation
import XCTest

@testable import Model

@MainActor
final class DependencyTests: XCTestCase {

  var disposable: AnyDisposable?

  override func setUpWithError() throws {}

  override func tearDownWithError() throws {
    disposable = nil
  }

  func test_routeIdentity() throws {
    let testModel =
      TestModel(
        store: .init(
          rootState: .init(
            someString: "Loop",
            twoState: .init()
          )
        )
      )

    XCTAssertNoThrow(
      disposable =
        try testModel
        ._startAsRoot(
          config: .defaults,
          annotations: []
        )
    )

    XCTAssertEqual(testModel.depOne, "DEFAULT_VALUE")

    let m2 = try XCTUnwrap(testModel.two)

    XCTAssertEqual(m2.propertyOne, "INJECTED_VALUE_TWO")
    XCTAssertEqual(m2.store.dependencies.testOne, "INJECTED_VALUE_TWO")

    testModel.store.transaction { $0.twoState = nil }
    let m3 = try XCTUnwrap(testModel.three)

    XCTAssertEqual(m3.fieldOne, "INJECTED_VALUE_THREE")
    XCTAssertEqual(m3.store.dependencies.testOne, "INJECTED_VALUE_THREE")
  }

}
