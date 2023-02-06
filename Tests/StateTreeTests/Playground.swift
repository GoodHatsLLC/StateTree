import Disposable
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - Playground

@TreeActor
final class Playground: XCTestCase {

  let stage = DisposableStage()

  override func tearDown() {
    stage.reset()
  }

  func test_intentStep_decoding() async throws {
    let step = Step(name: "myintent", fields: ["payload": "somepayload"])
    let myStep = try step.decode(as: MyIntent.self)
    XCTAssertEqual(MyIntent(payload: "somepayload"), myStep)
  }
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
