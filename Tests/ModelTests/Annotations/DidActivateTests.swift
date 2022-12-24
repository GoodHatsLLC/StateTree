import Behavior
import Disposable
import Model
import SourceLocation
import Tree
import XCTest

@MainActor
final class DidActivateTests: XCTestCase {

  let stage = DisposalStage()

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
    stage.reset()
  }

  func test_didActivateCalledOnce_onStart() async throws {
    var count = 0
    var leaf: TreeSegment?
    let didActivate: (TreeSegment) -> Void = { value in
      count += 1
      XCTAssertEqual(value, leaf)
    }

    leaf =
      try TreeSegment
      ._startedAsRoot(
        config: .init(
          hooks: Hooks(),
          startMode: .interactive,
          dependencies: .defaults
        ),
        stage: stage
      ) {
        .init(
          store: .init(
            rootState: .init(
              segment: .leaf(.init())
            )
          ),
          didActivate: didActivate
        )
      }

    await Task.flush()
    XCTAssertEqual(count, 1)
  }
}

private struct Hooks: StateTreeHooks {
  func didWriteChange(at: SourcePath) {}
  func wouldRun<B: BehaviorType>(behavior: B, from: SourceLocation) -> BehaviorInterception<
    B.Output
  > { .passthrough }
  func didRun<B: BehaviorType>(behavior: B, from: SourceLocation) {}
}
