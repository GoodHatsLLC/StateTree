import Disposable

// MARK: - Stage

/// TODO: replace with behavior oriented lifecycle handlers
@TreeActor
public struct Stage: Rules {

  // MARK: Lifecycle

  fileprivate init(builder: @escaping () -> AnyDisposable) {
    self.builder = builder
  }

  // MARK: Public

  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    switch lifecycle {
    case .didStart:
      builder().stage(on: stage)
    case .didUpdate:
      break
    case .willStop:
      stage.dispose()
    case .handleIntent:
      break
    }
    return .init()
  }

  public mutating func applyRule(with _: RuleContext) throws { }

  public mutating func removeRule(with _: RuleContext) throws { }

  public mutating func updateRule(
    from _: Self,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  private var builder: () -> AnyDisposable
  private let stage = DisposableStage()

}

extension Stage {

  public init(
    _ disposable: @escaping () -> some Disposable
  ) {
    self.init {
      disposable()
        .erase()
    }
  }

  public init(
    _ disposable: @autoclosure @escaping () -> some Disposable
  ) {
    self.init {
      disposable()
        .erase()
    }
  }
}
