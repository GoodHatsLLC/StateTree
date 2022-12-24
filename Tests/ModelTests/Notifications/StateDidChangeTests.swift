import Disposable
import Emitter
import Foundation
import Node
import XCTest

@testable import Model

@MainActor
final class StateDidChangeTests: XCTestCase {

  var stage: DisposalStage!
  var model: TestModel!

  override func setUpWithError() throws {
    stage = .init()
    model = TestModel(
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

  func test_noUpdateNotifications_beforeWrite() throws {
    var didUpdateCount = 0
    model.store._storage.stateDidChange
      .subscribe { _ in
        didUpdateCount += 1
      }
      .stage(on: stage)

    model.store._storage.observedStateDidChange
      .subscribe { _ in
        didUpdateCount += 1
      }
      .stage(on: stage)

    XCTAssertEqual(didUpdateCount, 0)
  }

  func test_updateNotificationFires_onWrite() throws {
    var didUpdateCount = 0
    model.store._storage.stateDidChange
      .subscribe { _ in
        didUpdateCount += 1
      }
      .stage(on: stage)

    XCTAssertEqual(didUpdateCount, 0)

    model.store.transaction { $0.someString = "hello" }

    XCTAssertEqual(didUpdateCount, 1)
  }
}
