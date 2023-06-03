import Disposable
@_spi(Implementation) import StateTreeBase
import TreeActor
import XCTest

// MARK: - OnChangeTests

final class OnChangeTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_onChange_fibonacci() async throws {
    let tree = Tree(root: OnChangeNode())
    try tree.start()
    let node = try tree.assume.rootNode
    XCTAssertEqual(node.record, [0, 1, 1, 2, 3, 5, 8, 13, 21, 34])
  }
}

// MARK: - OnChangeNode

struct OnChangeNode: Node {
  @Value var record: [Int] = [0]
  var rules: some Rules {
    OnStart {
      record.append(1)
    }
    OnChange(record) { old, new in
      // We're taking advantage of a circular update.
      // Maybe in the future this won't be allowed!
      guard record.count < 10
      else {
        return
      }

      record.append(old.last! + new.last!)
    }
  }
}
