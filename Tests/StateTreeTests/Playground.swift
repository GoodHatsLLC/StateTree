import Disposable
import Intents
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - Playground

final class Playground: XCTestCase {

  let stage = DisposableStage()

  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_something_async() async throws { }
}

extension Playground {

  struct MyIntent: IntentStep, Equatable {
    static let name = "myintent"
    let payload: String
  }

  struct Parent: Node {
    var rules: some Rules { () }
  }

}
