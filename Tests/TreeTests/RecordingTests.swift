import Disposable
import Foundation
import Model
import Tree
import TreeJSON
import XCTest

@MainActor
final class RecordingTests: XCTestCase {

  var stage: DisposalStage = .init()

  override func setUpWithError() throws {
    stage = .init()
  }

  override func tearDownWithError() throws {
    stage.dispose()
  }

  func test_recording_recordInitialStateWithoutChange() throws {
    let recorder = JSONTreeStateRecord()

    let tree = Tree<TestModel>(
      rootModelState: .init(),
      hooks: .init()
    ) { store in
      TestModel(store: store)
    }

    XCTAssertEqual(recorder.patches.count, 0)

    try tree
      .start(options: [.statePlayback(mode: .record(recorder))])
      .stage(on: stage)

    XCTAssertEqual(recorder.patches.count, 1)
    XCTAssertEqual(recorder.errors.count, 0)
    XCTAssertEqual(recorder._temp.count, 0)
  }

  func test_recording_onePatchPerWrite() throws {
    let recorder = JSONTreeStateRecord()

    let tree = Tree<TestModel>(
      rootModelState: .init(),
      hooks: .init()
    ) { store in
      TestModel(store: store)
    }

    try tree
      .start(options: [.statePlayback(mode: .record(recorder))])
      .stage(on: stage)

    // initial state record.
    XCTAssertEqual(recorder.patches.count, 1)
    // only the root is active
    XCTAssertEqual(recorder.patches.last?.statePatches.count, 1)

    // A change triggering a routed model containing the change
    tree.rootModel.store.transaction { state in
      state.words = "hello words"
    }
    XCTAssertEqual(tree.rootModel.store.read.words, "hello words")
    XCTAssertEqual(recorder.patches.count, 2)
    // two models, the root and its route, are active.
    XCTAssertEqual(recorder.patches.last?.statePatches.count, 2)

    // A change that doesn't trigger any routing
    tree.rootModel.words?.store.transaction { state in
      state.otherWords = "other words"
    }
    XCTAssertEqual(recorder.patches.count, 3)
    // two models, the root and its route, are active.
    XCTAssertEqual(recorder.patches.last?.statePatches.count, 2)

    // A change that triggers routing removing its model
    tree.rootModel.words?.store.transaction { state in
      state.words = "other words"
    }
    XCTAssertEqual(recorder.patches.count, 4)
    // only the root is now active
    XCTAssertEqual(recorder.patches.last?.statePatches.count, 1)

    // A change that triggers 3 route creations
    tree.rootModel.store.transaction { state in
      state.text = "hello text"
      state.string = "hello string"
      state.words = "hello words"
    }

    XCTAssertEqual(recorder.patches.count, 5)
    // the root and its 3 routes are all active
    XCTAssertEqual(recorder.patches.last?.statePatches.count, 4)

    // A change that triggers 3 route removals
    tree.rootModel.store.transaction { state in
      state.text = "goodbye text"
      state.string = "goodbye string"
      state.words = "goodbye words"
    }
    XCTAssertEqual(recorder.patches.count, 6)
    // all sub-routes are removed and only the root is active
    XCTAssertEqual(recorder.patches.last?.statePatches.count, 1)

    // There shouldn't be errors or temporary state.
    XCTAssertEqual(recorder.errors.count, 0)
    XCTAssertEqual(recorder._temp.count, 0)
  }
}
