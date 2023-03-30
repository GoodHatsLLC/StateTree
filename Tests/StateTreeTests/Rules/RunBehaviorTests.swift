import Disposable
import Emitter
import Utilities
import XCTest
@testable import StateTree

// MARK: - RunBehaviorTests

final class RunBehaviorTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_RunBehavior_finish() async throws {
    let subject = Async.Subject<Int>()
    var events: [Event] = []
    let tree = try Tree.main
      .start(
        root: OnBehaviorManager(
          sequence: subject,
          handler: {
            events.append($0)
          }
        )
      )
    XCTAssert(tree.info.behaviors.count == 1)
    tree.stage(on: stage)
    try await tree.awaitReady()
    subject.send(1)
    subject.send(2)
    subject.finish()
    let res = await tree.behaviorResolutions
    XCTAssertEqual(res.map(\.state), [.finished])
    XCTAssertEqual(
      events,
      [
        .value(1),
        .value(2),
        .finish,
      ]
    )
  }

  @TreeActor
  func test_RunBehavior_fail() async throws {
    let subject = Async.ThrowingSubject<Int>()
    var events: [Event] = []
    let tree = try Tree.main
      .start(
        root: OnBehaviorManager(
          sequence: subject,
          handler: { events.append($0) }
        )
      )
    tree.stage(on: stage)
    try await tree.awaitReady()
    XCTAssert(tree.info.behaviors.count == 1)
    subject.send(1)
    subject.fail(TestError())
    subject.finish()
    _ = await tree.behaviorResolutions
    XCTAssertEqual(
      events,
      [
        .value(1),
        .failed,
      ]
    )
  }

  @TreeActor
  func test_RunBehavior_emitter() async throws {
    let subject = PublishSubject<Int>()
    var events: [Event] = []
    let tree = try Tree.main
      .start(
        root: EmitterBehaviorManager(
          emitter: subject,
          handler: {
            events.append($0)
          }
        )
      )
    XCTAssert(tree.info.behaviors.count == 1)
    tree.stage(on: stage)
    try await tree.awaitReady()
    subject.emit(value: 1)
    subject.emit(value: 2)
    subject.finish()
    subject.fail(TestError())
    let res = await tree.behaviorResolutions
    XCTAssertEqual(res.map(\.state), [.finished])
    XCTAssertEqual(
      events,
      [
        .value(1),
        .value(2),
        .finish,
      ]
    )
  }
}

#if canImport(Combine)
import Combine
extension RunBehaviorTests {

  struct CombineBehaviorManager: Node {

    let publisher: AnyPublisher<Int, Never>
    let handler: (Event) -> Void

    var rules: some Rules {
      RunBehavior {
        publisher
      } onValue: { value in
        handler(.value(value))
      } onFinish: {
        handler(.finish)
      } onFailure: { _ in
        handler(.failed)
      }
    }
  }

  @TreeActor
  func test_RunBehavior_publisher() async throws {
    let publisher = [1, 2, 4, 4, 2].publisher
    var events: [Event] = []
    let tree = try Tree.main
      .start(
        root: CombineBehaviorManager(
          publisher: publisher.eraseToAnyPublisher(),
          handler: {
            events.append($0)
          }
        )
      )
    XCTAssert(tree.info.behaviors.count == 1)
    tree.stage(on: stage)
    try await tree.awaitReady()
    let res = await tree.behaviorResolutions
    XCTAssertEqual(res.map(\.state), [.finished])
    XCTAssertEqual(
      events,
      [
        .value(1),
        .value(2),
        .value(4),
        .value(4),
        .value(2),
        .finish,
      ]
    )
  }

  @TreeActor
  func test_RunBehavior_subject() async throws {
    let subject = PassthroughSubject<Int, Never>()
    var events: [Event] = []
    let tree = try Tree.main
      .start(
        root: CombineBehaviorManager(
          publisher: subject.eraseToAnyPublisher(),
          handler: {
            events.append($0)
          }
        )
      )
    XCTAssert(tree.info.behaviors.count == 1)
    tree.stage(on: stage)
    try await tree.awaitReady()
    subject.send(1)
    subject.send(2)
    subject.send(4)
    subject.send(4)
    subject.send(2)
    subject.send(completion: .finished)
    let res = await tree.behaviorResolutions
    XCTAssertEqual(res.map(\.state), [.finished])
    XCTAssertEqual(
      events,
      [
        .value(1),
        .value(2),
        .value(4),
        .value(4),
        .value(2),
        .finish,
      ]
    )
  }

}
#endif

extension RunBehaviorTests {

  enum Event: Equatable {
    case value(Int)
    case finish
    case failed
  }

  struct EmitterBehaviorManager<E: Emitting>: Node where E.Output == Int {

    let emitter: E
    let handler: (Event) -> Void

    var rules: some Rules {
      RunBehavior {
        emitter
      } onValue: { value in
        handler(.value(value))
      } onFinish: {
        handler(.finish)
      } onFailure: { _ in
        handler(.failed)
      }
    }
  }

  struct OnBehaviorManager<Seq: AsyncSequence>: Node where Seq.Element == Int {

    let sequence: Seq
    let handler: (Event) -> Void
    func asyncEmitting() async -> Seq {
      sequence
    }

    var rules: some Rules {
      RunBehavior {
        await asyncEmitting()
      } onValue: { value in
        handler(.value(value))
      } onFinish: {
        handler(.finish)
      } onFailure: { _ in
        handler(.failed)
      }
    }
  }

  struct TestError: Error, Equatable { }

}
