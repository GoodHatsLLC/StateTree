import Disposable
import Emitter
import Foundation
import Node
import XCTest

@testable import Model

@MainActor
final class ImplementationRetentionTests: XCTestCase {

  var disposable: AnyDisposable?

  override func setUpWithError() throws {}

  override func tearDownWithError() throws {
    disposable = nil
  }

  func test_dispose_releasesActiveModelAndNode() throws {
    weak var weakThreeModel: ActiveModel<ThreeModel>? = nil
    weak var weakThreeNode: Node<ThreeModel.State>? = nil
    let testModel = TestModel(
      store: .init(
        rootState: .init()
      )
    )

    try autoreleasepool {
      disposable = try testModel._startAsRoot(
        config: .defaults,
        annotations: []
      )
      // Reach in to get the underlying identity based storage
      let threeModel = try XCTUnwrap(testModel.three?.store._storage.activeModel.value)
      weakThreeModel = threeModel
      // ... and the Node from the state graph within it.
      weakThreeNode = threeModel.node
      XCTAssertNotNil(weakThreeModel)
      XCTAssertNotNil(weakThreeNode)
      // stopping the root should release all routes
      // and their underlying 'Node' state storage.
      disposable?.dispose()
      disposable = nil
    }

    XCTAssertNil(weakThreeModel)
    XCTAssertNil(weakThreeNode)
  }

  func test_dispose_releasesActiveModelAndNode_routedRecursively() throws {
    let recursiveDepth = 100

    let testModel =
      TestModel(
        store: .init(
          rootState: .init(
            someString: String(repeating: "Loop", count: recursiveDepth - 1),
            twoState: .init()
          )
        )
      )

    var models: [WeakRef<ActiveModel<TestModel>>] = []
    var nodes: [WeakRef<Node<TestModel.State>>] = []

    func count() -> Int {
      let c1 = models.compactMap { $0.ref }.count
      let c2 = nodes.compactMap { $0.ref }.count
      XCTAssertEqual(c1, c2)
      return c1
    }

    func accumulate(model: TestModel) {
      if let activeModel = model.store._storage.activeModel.value {
        models.append(WeakRef(activeModel))
        nodes.append(WeakRef(activeModel.node))
      }
      if let next = model.test {
        accumulate(model: next)
      }
    }

    try autoreleasepool {
      disposable = try testModel._startAsRoot(
        config: .defaults,
        annotations: []
      )
      accumulate(model: testModel)
      XCTAssertEqual(count(), recursiveDepth)
      disposable = nil
    }
    XCTAssertEqual(count(), 0)
  }

}
