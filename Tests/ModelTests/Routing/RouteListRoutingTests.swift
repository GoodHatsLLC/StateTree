import Disposable
import Emitter
import Foundation
import Node
import XCTest

@testable import Model

@MainActor
final class RouteListRoutingTests: XCTestCase {

  var disposable: AnyDisposable?

  override func setUpWithError() throws {}

  override func tearDownWithError() throws {
    disposable = nil
  }

  func test_attachOrder() throws {
    let state = ListRouteTestModel.State(
      submodelInfo: [
        .init(id: UUID(), sharedState: "one"),
        .init(id: UUID(), sharedState: "two"),
        .init(id: UUID(), sharedState: "three"),
        .init(id: UUID(), sharedState: "four"),
      ]
    )
    let testModel = ListRouteTestModel(
      store: .init(rootState: state)
    )

    XCTAssertNoThrow(
      disposable = try testModel._startAsRoot(
        config: .defaults,
        annotations: []
      )
    )

    XCTAssertEqual(testModel.identifiableModels.count, 4)
    XCTAssertEqual(testModel.identifiableModels[0].store.read.sharedState, "one")
    XCTAssertEqual(testModel.identifiableModels[1].store.read.sharedState, "two")
    XCTAssertEqual(testModel.identifiableModels[2].store.read.sharedState, "three")
    XCTAssertEqual(testModel.identifiableModels[3].store.read.sharedState, "four")
  }

  func test_stateChange_propagatesDown() throws {
    let state = ListRouteTestModel.State(
      submodelInfo: [
        .init(id: UUID(), sharedState: "one"),
        .init(id: UUID(), sharedState: "two"),
        .init(id: UUID(), sharedState: "three"),
        .init(id: UUID(), sharedState: "four"),
      ]
    )
    let testModel = ListRouteTestModel(
      store: .init(rootState: state)
    )

    XCTAssertNoThrow(
      disposable = try testModel._startAsRoot(
        config: .defaults,
        annotations: []
      )
    )

    testModel.store.transaction { state in
      state.submodelInfo[2].sharedState = "SOME EDIT"
    }

    XCTAssertEqual(testModel.store.read.submodelInfo[0].sharedState, "one")
    XCTAssertEqual(testModel.store.read.submodelInfo[1].sharedState, "two")
    XCTAssertEqual(testModel.store.read.submodelInfo[2].sharedState, "SOME EDIT")
    XCTAssertEqual(testModel.store.read.submodelInfo[3].sharedState, "four")

    XCTAssertEqual(testModel.identifiableModels[0].store.read.sharedState, "one")
    XCTAssertEqual(testModel.identifiableModels[1].store.read.sharedState, "two")
    XCTAssertEqual(testModel.identifiableModels[2].store.read.sharedState, "SOME EDIT")
    XCTAssertEqual(testModel.identifiableModels[3].store.read.sharedState, "four")
  }

  func test_stateChange_propagatesUp() throws {
    let state = ListRouteTestModel.State(
      submodelInfo: [
        .init(id: UUID(), sharedState: "one"),
        .init(id: UUID(), sharedState: "two"),
        .init(id: UUID(), sharedState: "three"),
        .init(id: UUID(), sharedState: "four"),
      ]
    )
    let testModel = ListRouteTestModel(
      store: .init(rootState: state)
    )

    XCTAssertNoThrow(
      disposable = try testModel._startAsRoot(
        config: .defaults,
        annotations: []
      )
    )

    testModel.identifiableModels[3].store.transaction { state in
      state.sharedState = "SOME EDIT"
    }

    XCTAssertEqual(testModel.store.read.submodelInfo[0].sharedState, "one")
    XCTAssertEqual(testModel.store.read.submodelInfo[1].sharedState, "two")
    XCTAssertEqual(testModel.store.read.submodelInfo[2].sharedState, "three")
    XCTAssertEqual(testModel.store.read.submodelInfo[3].sharedState, "SOME EDIT")

    XCTAssertEqual(testModel.identifiableModels[0].store.read.sharedState, "one")
    XCTAssertEqual(testModel.identifiableModels[1].store.read.sharedState, "two")
    XCTAssertEqual(testModel.identifiableModels[2].store.read.sharedState, "three")
    XCTAssertEqual(testModel.identifiableModels[3].store.read.sharedState, "SOME EDIT")
  }

  func test_editedHead_remapsTail() throws {
    let testModel = ListRouteTestModel(
      store: .init(rootState: .init(submodelInfo: []))
    )

    XCTAssertNoThrow(
      disposable = try testModel._startAsRoot(
        config: .defaults,
        annotations: []
      )
    )

    testModel.add("a")
    testModel.add("b")
    testModel.add("c")
    testModel.add("d")
    let a = testModel.identifiableModels[0].id
    let b = testModel.identifiableModels[1].id
    let c = testModel.identifiableModels[2].id
    let d = testModel.identifiableModels[3].id
    testModel.edit(id: d, value: "DDD")
    testModel.add("III")
    let i = try XCTUnwrap(testModel.identifiableModels.last).id
    testModel.remove(id: a)
    XCTAssertEqual(
      testModel.identifiableModels.map {
        $0.value
      },
      ["b", "c", "DDD", "III"]
    )
    XCTAssertEqual(
      testModel.identifiableModels.map { $0.id },
      [b, c, d, i]
    )
  }

  func test_remappedTail_isEditable() throws {
    let testModel = ListRouteTestModel(
      store: .init(rootState: .init(submodelInfo: []))
    )

    XCTAssertNoThrow(
      disposable = try testModel._startAsRoot(
        config: .defaults,
        annotations: []
      )
    )

    testModel.add("a")
    testModel.add("b")
    testModel.add("c")
    testModel.add("d")
    let a = testModel.identifiableModels[0].id
    let b = testModel.identifiableModels[1].id
    let c = testModel.identifiableModels[2].id
    let d = testModel.identifiableModels[3].id
    testModel.edit(id: d, value: "DDD")
    testModel.add("III")
    let i = try XCTUnwrap(testModel.identifiableModels.last).id
    testModel.remove(id: a)
    testModel.edit(id: d, value: "YOLO1")
    testModel.edit(id: i, value: "YOLO2")
    XCTAssertEqual(
      testModel.identifiableModels.map {
        $0.value
      },
      ["b", "c", "YOLO1", "YOLO2"]
    )
    XCTAssertEqual(
      testModel.identifiableModels.map { $0.id },
      [b, c, d, i]
    )
  }

  func test_remappedTail_isDeletable() throws {
    let testModel = ListRouteTestModel(
      store: .init(rootState: .init(submodelInfo: []))
    )

    XCTAssertNoThrow(
      disposable = try testModel._startAsRoot(
        config: .defaults,
        annotations: []
      )
    )

    testModel.add("a")
    testModel.add("b")
    testModel.add("c")
    testModel.add("d")
    let a = testModel.identifiableModels[0].id
    let b = testModel.identifiableModels[1].id
    let c = testModel.identifiableModels[2].id
    let d = testModel.identifiableModels[3].id
    testModel.edit(id: d, value: "DDD")
    testModel.add("III")
    let i = try XCTUnwrap(testModel.identifiableModels.last).id
    testModel.remove(id: a)
    testModel.remove(id: b)
    testModel.remove(id: i)
    XCTAssertEqual(
      testModel.identifiableModels.map {
        $0.value
      },
      ["c", "DDD"]
    )
    XCTAssertEqual(
      testModel.identifiableModels.map { $0.id },
      [c, d]
    )
  }

}
