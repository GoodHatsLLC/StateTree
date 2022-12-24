import Disposable
import Emitter
import Foundation
import Node
import XCTest

@testable import Model

@MainActor
final class ChangeRootTests: XCTestCase {

  var stage: DisposalStage!
  var root: TreeSegment!
  var rootEventCount = 0
  var trunkLength = 0
  var trunkEventCount = 0
  var leaf: TreeSegment!
  var leafEventCount = 0

  override func setUpWithError() throws {
    stage = .init()
    root =
      try TreeSegment
      .start(
        stage: stage,
        path: .root(.trunk(.taper(.taper(.leaf(.init()))))))
    root.store.events
      .subtreeDidChange
      .subscribe { _ in
        self.rootEventCount += 1
      }
      .stage(on: stage)

    var trunk: TreeSegment!
    trunk = root
    while trunk.lhs!.type != .leaf {
      trunkLength += 1
      trunk = trunk.lhs!
      trunk.store.events
        .subtreeDidChange
        .subscribe { _ in
          self.trunkEventCount += 1
        }
        .stage(on: stage)
    }

    leaf = trunk.lhs!
    leaf.store.events
      .subtreeDidChange
      .subscribe { _ in
        self.leafEventCount += 1
      }
      .stage(on: stage)

    XCTAssertEqual(trunkLength, 3)
  }

  override func tearDownWithError() throws {
    stage.dispose()
    stage = nil
    root = nil
    rootEventCount = 0
    trunkLength = 0
    trunkEventCount = 0
    leaf = nil
    leafEventCount = 0
  }

  func test_onlyRootFires_whenRootAndLeafChange() throws {
    XCTAssertEqual(rootEventCount, 0)
    XCTAssertEqual(trunkEventCount, 0)
    XCTAssertEqual(leafEventCount, 0)
    leaf.store.modify.name = "new name"
    XCTAssertEqual(rootEventCount, 1)
    XCTAssertEqual(trunkEventCount, 0)
    XCTAssertEqual(leafEventCount, 0)
  }

}
