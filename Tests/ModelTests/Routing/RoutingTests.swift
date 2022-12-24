import Disposable
import Emitter
import Foundation
import Node
import XCTest

@testable import Model

@MainActor
final class RoutingTests: XCTestCase {

  var disposable: AnyDisposable?

  override func setUpWithError() throws {}

  override func tearDownWithError() throws {
    disposable = nil
  }

  func test_oneRoute() throws {
    let testModel = TestModel(
      store: .init(
        rootState: .init()
      )
    )
    XCTAssertNil(testModel.three)
    XCTAssertNil(testModel.two)
    XCTAssertNil(testModel.test)

    XCTAssertNoThrow(
      disposable = try testModel._startAsRoot(
        config: .defaults,
        annotations: []
      )
    )

    XCTAssertNotNil(testModel.three)
    XCTAssertNil(testModel.two)
    XCTAssertNil(testModel.test)
  }

  func test_twoRoutes() throws {
    let testModel =
      TestModel(
        store: .init(
          rootState: .init(
            someString: "Loop",
            twoState: .init()
          )
        )
      )

    XCTAssertNil(testModel.three)
    XCTAssertNil(testModel.two)
    XCTAssertNil(testModel.test)

    XCTAssertNoThrow(
      disposable =
        try testModel
        ._startAsRoot(
          config: .defaults,
          annotations: []
        )
    )

    XCTAssertNil(testModel.three)
    XCTAssertNotNil(testModel.two)
    XCTAssertNotNil(testModel.test)

    XCTAssertNil(testModel.test?.test)
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

    let id1 = try XCTUnwrap(testModel.store._storage.routeIdentity)
    let id2 = try XCTUnwrap(testModel.two?.store._storage.routeIdentity)
    let idTest = try XCTUnwrap(testModel.test?.store._storage.routeIdentity)

    testModel.store.transaction { $0.twoState = nil }
    let id3 = try XCTUnwrap(testModel.three?.store._storage.routeIdentity)

    XCTAssertNotEqual(idTest, id1)
    XCTAssertNotEqual(idTest, id2)
    XCTAssertNotEqual(idTest, id3)
    XCTAssertNotEqual(id1, id2)
    XCTAssertNotEqual(id1, id3)
    XCTAssertNotEqual(id2, id3)
  }

  func test_recursiveRouting() throws {
    let recursiveDepth = 100

    func assertCount(model: TestModel, count: Int) throws {
      if count == 0 {
        XCTAssertNil(model.test)
      } else {
        try assertCount(model: XCTUnwrap(model.test), count: count - 1)
      }
    }

    let testModel =
      TestModel(
        store: .init(
          rootState: .init(
            someString: String(repeating: "Loop", count: recursiveDepth),
            twoState: .init()
          )
        )
      )

    // should recursively create an submodule for each "Loop"
    disposable = try testModel._startAsRoot(
      config: .defaults,
      annotations: []
    )

    try assertCount(model: testModel, count: recursiveDepth)
  }

}
