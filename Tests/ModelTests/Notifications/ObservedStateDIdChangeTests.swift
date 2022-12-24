import Disposable
import Emitter
import Foundation
import Node
import XCTest

@testable import Model

@MainActor
final class ObservedStateDidChangeTests: XCTestCase {

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

  func test_accessedPathsUpdateNotification_fires_onAccessedWrite() throws {
    var didUpdateCount = 0
    model.store._storage.observedStateDidChange
      .subscribe { _ in
        didUpdateCount += 1
      }
      .stage(on: stage)

    XCTAssertEqual(didUpdateCount, 0)

    _ = model.store.read.someString
    model.store.transaction { $0.someString = "hello" }

    XCTAssertEqual(didUpdateCount, 1)
  }

  func test_accessedPathsUpdateNotification_doesNotFires_onUnAccessedWrite() throws {
    var didUpdateCount = 0
    model.store._storage.observedStateDidChange
      .subscribe { _ in
        didUpdateCount += 1
      }
      .stage(on: stage)

    XCTAssertEqual(didUpdateCount, 0)

    _ = model.store.read.someOtherString
    model.store.transaction { $0.someString = "hello" }

    XCTAssertEqual(didUpdateCount, 0)
  }

}
