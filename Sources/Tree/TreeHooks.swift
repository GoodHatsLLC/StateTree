import Behavior
import BehaviorInterface
import Dependencies
import Disposable
import Emitter
import Foundation
import Model
import SourceLocation
import Utilities

// MARK: - TreeHooks

@MainActor
public final class TreeHooks: StateTreeHooks {

  nonisolated public init() {}

  public func didWriteChange(at identity: SourcePath) {
    changeReceiver.emit(.value(identity))
  }

  public func wouldRun<B: BehaviorType>(
    behavior: B,
    from location: SourceLocation
  ) -> BehaviorInterception<B.Output> {
    guard isMocking
    else {
      return .swap(action: behavior.action)
    }
    let id = behavior.id
    let untypedMock = activeMocks[id]
    let mock =
      untypedMock
      .flatMap {
        $0 as? BehaviorInterception<B.Output>
      }

    if let mock {
      return mock
    }

    DependencyValues.defaults.logger.error(
      message:
        """
        Un-mocked Behavior id: \(id)
        init location: \(behavior._initLocation.description)
        run location: \(location.description)
        \(
                untypedMock
                    .map {
                        "incorrect mock type: \(String(describing: $0)) (expected: \(String(describing: BehaviorInterception<B.Output>.self)))"
                    } ?? ""
            )
        """
    )
    return .cancel
  }

  public func mockBehaviors(
    _ mocks: [String: any BehaviorInterceptionType],
    within block: () -> Void
  ) {
    activeMocks = mocks
    isMocking = true
    defer {
      activeMocks = [:]
      isMocking = false
    }
    block()
  }

  public func didRun<B: BehaviorType>(behavior: B, from location: SourceLocation) {
    behaviorRunPublishSubject.emit(.value((behavior, location)))
  }

  public func expectBehaviors(
    _ effects: String...,
    within block: () -> Void
  ) throws
    -> Bool
  {
    let expectedIDs = Set(effects)
    var received: [BehaviorRun] = []
    let disposable =
      behaviorRunPublishSubject
      .subscribe { run in
        received.append(run)
      }
    block()
    disposable.dispose()
    let receivedIDs = Set(received.compactMap { $0.effect.id })
    if receivedIDs == expectedIDs {
      return true
    }
    let missingIDs =
      expectedIDs
      .subtracting(receivedIDs)
      .map { $0 }
    let unexpectedBehaviors =
      received
      .map { run in
        (
          id: run.effect.id,
          initLocation: run.effect._initLocation.description,
          runLocation: run.runLocation.description
        )
      }
    throw MissingBehaviors(
      missingBehaviors: missingIDs,
      unexpectedBehaviors: unexpectedBehaviors
    )
  }

  typealias BehaviorRun = (effect: any BehaviorType, runLocation: SourceLocation)

  var didChangeEmitter: some Emitter<SourcePath> {
    changeReceiver
  }

  private let changeReceiver = PublishSubject<SourcePath>()
  private let behaviorRunPublishSubject = PublishSubject<BehaviorRun>()

  private var activeMocks: [String: any BehaviorInterceptionType] = [:]
  private var isMocking = false

}
