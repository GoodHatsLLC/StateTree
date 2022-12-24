import BehaviorInterface
import SourceLocation

// MARK: - StateTreeHooks

@MainActor
public protocol StateTreeHooks {
  func didWriteChange(at: SourcePath)
  func wouldRun<B: BehaviorType>(behavior: B, from: SourceLocation) -> BehaviorInterception<
    B.Output
  >
  func didRun<B: BehaviorType>(behavior: B, from: SourceLocation)
}

// MARK: - NoopTreeHooks

public struct NoopTreeHooks: StateTreeHooks {
  nonisolated public init() {}
  public func didWriteChange(at _: SourcePath) {}

  public func wouldRun<B: BehaviorType>(
    behavior _: B,
    from _: SourceLocation
  ) -> BehaviorInterception<B.Output> {
    .cancel
  }

  public func didRun<B: BehaviorType>(behavior _: B, from _: SourceLocation) {}
}

extension StateTreeHooks where Self == NoopTreeHooks {
  nonisolated public static var noop: NoopTreeHooks { NoopTreeHooks() }
}
