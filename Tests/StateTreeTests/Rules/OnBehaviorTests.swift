// import Emitter
// import XCTest
import Disposable
// @_spi(Implementation) @testable import StateTree
//
//// MARK: - OnBehaviorTests
//
// final class OnBehaviorTests: XCTestCase {
//
//  let stage = DisposableStage()
//
//  override func setUp() { }
//  override func tearDown() {
//    stage.reset()
//  }
//
//  @TreeActor
//  func test_onReceive_finish() async throws {
//    let subject = PublishSubject<Int>()
//    var events: [Event] = []
//    let tree = try Tree.main
//      .start(
//        root: OnBehaviorManager(
//          emitter: subject.erase(),
//          handler: {
//            events.append($0)
//          }
//        )
//      )
//    tree.stage(on: stage)
//    subject.emit(value: 1)
//    subject.emit(value: 2)
//    subject.finish()
//    subject.fail(TestError())
//    _ = await tree.behaviorResolutions
//    XCTAssertEqual(
//      events,
//      [
//        .value(1),
//        .value(2),
//        .finish,
//      ]
//    )
//  }
//
//  @TreeActor
//  func test_onReceive_fail() async throws {
//    let subject = PublishSubject<Int>()
//    var events: [Event] = []
//    let tree = try Tree.main
//      .start(
//        root: OnBehaviorManager(
//          emitter: subject.erase(),
//          handler: { events.append($0) }
//        )
//      )
//    tree.stage(on: stage)
//    subject.emit(value: 1)
//    subject.fail(TestError())
//    subject.finish()
//    _ = await tree.behaviorResolutions
//    XCTAssertEqual(
//      events,
//      [
//        .value(1),
//        .failed,
//      ]
//    )
//  }
// }
//
// extension OnBehaviorTests {
//
//  enum Event: Equatable {
//    case value(Int)
//    case finish
//    case cancel
//    case failed
//  }
//
//  struct OnBehaviorManager: Node {
//
//    let emitter: AnyEmitter<Int>
//    let handler: (Event) -> Void
//
//    var rules: some Rules {
//      OnBehavior(emitted: emitter) { value in
//        handler(.value(value))
//      } onFinish: {
//        handler(.finish)
//      } onCancel: {
//        handler(.cancel)
//      } onFailure: { _ in
//        handler(.failed)
//      }
//    }
//  }
//
//  struct TestError: Error { }
//
// }
