import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - BehaviorStreamTests

final class BehaviorStreamTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }
  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func test_success() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    life
      .stage(on: stage)
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)

    let expected = [1, 2, 3, 4, 5, 6]
    var received: [Int] = []
    var didFinish = false
    let asyncBlock = AsyncValue<Void>()
    let subnodeResolution = subnode
      .$scope
      .run(.id("test_output_success")) {
        AnyAsyncSequence(expected)
      }
      .onOutput { value in
        received.append(value)
      } onFinish: {
        didFinish = true
        asyncBlock.resolve(())
      } onFail: { _ in
        XCTFail()
      }
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("test_output_success"))
    XCTAssertEqual(resolved.state, .finished)
    await asyncBlock.value
    XCTAssert(didFinish)
    XCTAssertEqual(received.sorted(), expected.sorted())
  }

  @TreeActor
  func test_immediate_failure() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    struct TestError: Error { }
    life
      .stage(on: stage)
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)

    var receivedError: Error?
    let subnodeResolution = subnode
      .$scope
      .run(.id("stream_fail")) { () throws -> AnyAsyncSequence<Int> in
        throw TestError()
      }
      .onOutput { _ in
        XCTFail()
      } onFinish: {
        XCTFail()
      } onFail: { error in
        receivedError = error
      }
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("stream_fail"))
    XCTAssertEqual(resolved.state, .failed)
    XCTAssert(receivedError is TestError)
  }

  @TreeActor
  func test_eventual_failure() async throws {
    let life = try Tree.main
      .start(root: RootNode())
    struct TestError: Error { }
    life
      .stage(on: stage)
    let subnode = try XCTUnwrap(life.rootNode.scopedNode)
    let subject = PublishSubject<Int>()
    var receivedError: Error?
    var receivedOutput: [Int] = []
    let asyncBlocks: [AsyncValue<Void>] = [.init(), .init()]
    let subnodeResolution = subnode
      .$scope
      .run(.id("stream_eventual_fail")) {
        subject.values
      }
      .onOutput { value in
        receivedOutput.append(value)
        if receivedOutput.count == 3 {
          asyncBlocks[0].resolve(())
        }
      } onFinish: {
        XCTFail()
      } onFail: { error in
        receivedError = error
        asyncBlocks[1].resolve(())
      }
    subject.emit(.value(3))
    subject.emit(.value(4))
    subject.emit(.value(5))
    await asyncBlocks[0].value
    subject.emit(.failed(TestError()))
    await asyncBlocks[1].value
    subject.emit(.value(3))
    let resolved = await subnodeResolution.value
    XCTAssertEqual(resolved.id, .id("stream_eventual_fail"))
    XCTAssertEqual(resolved.state, .failed)
    XCTAssert(receivedError is TestError)
    XCTAssertEqual(receivedOutput.sorted(), [3, 4, 5])
  }

}

// MARK: BehaviorStreamTests.ScopeNode

extension BehaviorStreamTests {

  struct RootNode: Node {
    @Route(ScopeNode.self) var scopedNode
    var rules: some Rules {
      $scopedNode.route(
        to: ScopeNode()
      )
    }
  }

  // MARK: - ScopeNode

  struct ScopeNode: Node {

    @Scope var scope

    var rules: some Rules {
      .none
    }

  }
}
