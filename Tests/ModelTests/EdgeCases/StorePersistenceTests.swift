import Disposable
import Emitter
import Foundation
import Node
import XCTest

@testable import Model

@MainActor
final class StorePersistenceTests: XCTestCase {

  var stage: DisposalStage!
  var root: StateHosting.Root!
  var leaf: StateHosting.Leaf!

  override func setUpWithError() throws {
    stage = .init()
    root = StateHosting.Root(
      store: .init(
        rootState: .init()
      )
    )
    try root
      ._startAsRoot(
        config: .defaults,
        annotations: []
      )
      .stage(on: stage)
    leaf = root.leaf
  }

  override func tearDownWithError() throws {
    stage.dispose()
    stage = nil
    root = nil
  }

  func test_lowerChanges_savedInUpdate() throws {
    XCTAssertEqual(root.counter, 0)
    XCTAssertEqual(leaf.counter, 0)
    XCTAssertEqual(leaf.value, "LEAF_DEFAULT")
    leaf.counter += 1
    XCTAssertEqual(root.counter, 1)
    XCTAssertEqual(leaf.counter, 1)
    leaf.value = "LEAF_NEW"
    XCTAssertEqual(leaf.value, "LEAF_NEW")
    leaf.setValueIncrementingCounter("LEAF_STATE_NOT_REINITIALIZED")
    XCTAssertEqual(root.counter, 2)
    XCTAssertEqual(leaf.counter, 2)
    XCTAssertNotEqual(leaf.value, "LEAF_DEFAULT")
    XCTAssertEqual(leaf.value, "LEAF_STATE_NOT_REINITIALIZED")
  }

}
