import Disposable
import Emitter
import Foundation
import Node
import XCTest

@testable import Model

@MainActor
final class IntermediateNodesUnchangedTests: XCTestCase {

  var stage: DisposalStage!
  var model: PartialMapping.BaseModel!

  override func setUpWithError() throws {
    stage = .init()
    model = PartialMapping.BaseModel(
      store: .init(
        rootState: .init()
      )
    )
    try model
      ._startAsRoot(
        config: .defaults,
        annotations: []
      )
      .stage(on: stage)
  }

  override func tearDownWithError() throws {
    stage.dispose()
    stage = nil
    model = nil
  }

  func test_changePropagates_despiteUnchangedIntermediateNodes() throws {
    var didChangeCount = 0

    // Check initial values and register for change notifications.
    let base = try XCTUnwrap(model)
    base.store.events.stateDidChange
      .subscribe { _ in
        didChangeCount += 1
      }
      .stage(on: stage)
    var next = try XCTUnwrap(base.next)
    next = try XCTUnwrap(next.next)
    next.store.events.stateDidChange
      .subscribe { _ in
        didChangeCount += 1
      }
      .stage(on: stage)
    XCTAssertEqual(next.store.read.value, "DEFAULT")
    next = try XCTUnwrap(next.next)
    next.store.events.stateDidChange
      .subscribe { _ in
        didChangeCount += 1
      }
      .stage(on: stage)
    XCTAssertEqual(next.store.read.value, "DEFAULT")
    let leaf = try XCTUnwrap(next.leaf)
    leaf.store.events.stateDidChange
      .subscribe { _ in
        didChangeCount += 1
      }
      .stage(on: stage)
    XCTAssertEqual(leaf.store.read.value, "LEAF_DEFAULT")

    leaf.store.transaction { state in
      state.value = "NEW_VALUE"
    }

    // Check new values propagate up despite intermediate
    // nodes not being changed.
    XCTAssertEqual(base.store.read.value, "NEW_VALUE")
    next = try XCTUnwrap(base.next)
    XCTAssertEqual(next.store.read.value, "DEFAULT")
    next = try XCTUnwrap(next.next)
    XCTAssertEqual(next.store.read.value, "DEFAULT")
    next = try XCTUnwrap(next.next)
    XCTAssertEqual(next.store.read.value, "DEFAULT")
    XCTAssertEqual(leaf.store.read.value, "NEW_VALUE")

    // Check changed nodes emit
    XCTAssertEqual(didChangeCount, 2)
  }

}
