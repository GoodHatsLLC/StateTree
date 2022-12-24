import Disposable
import Foundation
import Model
import Tree
import XCTest

@MainActor
final class StartTests: XCTestCase {

  var stage: DisposalStage = .init()

  override func setUpWithError() throws {
    stage = .init()
  }

  override func tearDownWithError() throws {
    stage.dispose()
  }

  func test_throws_onDoubleStart() throws {
    let tree = Tree<TestModel>(
      rootModelState: .init(),
      hooks: .init()
    ) { store in
      TestModel(store: store)
    }

    try tree.start(options: [.logging(threshold: .error)])
      .stage(on: stage)

    XCTAssertThrowsError(try tree.start())
  }

  func test_doesNotThrows_onStartAfterFinish() throws {
    let tree = Tree<TestModel>(
      rootModelState: .init(),
      hooks: .init()
    ) { store in
      TestModel(store: store)
    }

    let disposable = try tree.start(options: [.logging(threshold: .error)])
    disposable.dispose()

    XCTAssertNoThrow(try tree.start(options: [.logging(threshold: .error)]))
  }

}
