import Disposable
import Foundation
import Model
import Tree
import TreeJSON
import XCTest

@MainActor
final class PlaybackTests: XCTestCase {

  var stage: DisposalStage!
  var recorder: JSONTreeStateRecord!
  var tree: Tree<TestModel>!

  override func setUpWithError() throws {
    stage = .init()
    recorder = .init()
    tree = Tree<TestModel>(
      rootModelState: .init(),
      hooks: .init()
    ) { store in
      TestModel(store: store)
    }
  }

  override func tearDownWithError() throws {
    stage.dispose()
    stage = nil
    recorder = nil
    tree = nil
  }

  func test_makePlayer() throws {
    let startDisposable =
      try tree
      .start(options: [.logging(threshold: .error), .statePlayback(mode: .record(recorder))])

    startDisposable.dispose()

    let player = recorder.makePlayer()

    // Initial state
    XCTAssertEqual(player.frames.count, 1)
  }

  func test_tearDown_onDispose() throws {
    let startDisposable =
      try tree
      .start(options: [.logging(threshold: .error), .statePlayback(mode: .record(recorder))])

    tree
      .rootModel
      .store.transaction { state in
        state.words = "hello words"
      }

    // route should exist
    XCTAssertEqual(tree.rootModel.store.submodels.count, 1)

    startDisposable.dispose()

    // routes should reset on stop
    XCTAssertEqual(tree.rootModel.store.submodels.count, 0)
  }

  func test_makeMultipleFrames() throws {
    let startDisposable =
      try tree
      .start(options: [.logging(threshold: .error), .statePlayback(mode: .record(recorder))])

    tree
      .rootModel
      .store.transaction { state in
        state.string = "some text"
      }
    tree
      .rootModel
      .store.transaction { state in
        state.words = "hello words"
      }
    tree
      .rootModel
      .store.transaction { state in
        state.words = "hello string"
      }

    startDisposable.dispose()

    let player = recorder.makePlayer()

    XCTAssertEqual(player.frames.count, 4)
  }

  func test_playback() throws {
    var startDisposable =
      try tree
      .start(options: [.logging(threshold: .error), .statePlayback(mode: .record(recorder))])
    tree
      .rootModel
      .store.transaction { state in
        state.text = "hello text"
      }
    XCTAssertEqual(tree.rootModel.store.submodels.count, 1)
    tree
      .rootModel
      .store.transaction { state in
        state.words = "hello words"
      }
    XCTAssertEqual(tree.rootModel.store.submodels.count, 2)
    tree
      .rootModel
      .store.transaction { state in
        state.string = "hello string"
      }
    XCTAssertEqual(tree.rootModel.store.submodels.count, 3)

    tree
      .rootModel
      .store.transaction { state in
        state.numbers = [1, 2, 3]
      }
    XCTAssertEqual(tree.rootModel.store.submodels.count, 6)

    tree.rootModel.store.transaction { state in
      state.value = "NEW_VALUE"
    }

    startDisposable.dispose()
    XCTAssertEqual(tree.rootModel.store.submodels.count, 0)

    let player = recorder.makePlayer()

    startDisposable =
      try tree
      .start(options: [.logging(threshold: .error), .statePlayback(mode: .playback(player))])

    // apply zero — original pre-mutation state
    player.applyFrame(index: 0)
    XCTAssertEqual(tree.rootModel.store.submodels.count, 0)

    // apply first change — no routes
    player.applyFrame(index: 1)
    XCTAssertEqual(tree.rootModel.store.submodels.count, 1)

    // apply third — one route change
    player.applyFrame(index: 2)
    XCTAssertEqual(tree.rootModel.store.submodels.count, 2)

    // apply fourth — one route change
    player.applyFrame(index: 3)
    XCTAssertEqual(tree.rootModel.store.submodels.count, 3)

    player.applyFrame(index: 4)
    XCTAssertEqual(tree.rootModel.store.submodels.count, 6)

    XCTAssertEqual(tree.rootModel.numbers[0].store.read.value, "DEFAULT_VALUE")
    XCTAssertEqual(tree.rootModel.numbers[1].store.read.value, "DEFAULT_VALUE")
    XCTAssertEqual(tree.rootModel.numbers[2].store.read.value, "DEFAULT_VALUE")

    player.applyFrame(index: 5)

    XCTAssertEqual(tree.rootModel.numbers[0].store.read.value, "NEW_VALUE")
    XCTAssertEqual(tree.rootModel.numbers[1].store.read.value, "NEW_VALUE")
    XCTAssertEqual(tree.rootModel.numbers[2].store.read.value, "NEW_VALUE")
  }

}
