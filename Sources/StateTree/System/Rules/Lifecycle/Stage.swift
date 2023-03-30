@_spi(Implementation) import Behaviors
import Disposable

// MARK: - Stage

public struct Stage: Rules {

  // MARK: Lifecycle

  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    id: BehaviorID? = nil,
    _ disposable: @escaping () -> any Disposable
  ) {
    self.init(moduleFile: moduleFile, line: line, column: column, id: id, disposable())
  }

  public init(
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    id: BehaviorID? = nil,
    _ disposable: @autoclosure @escaping () -> any Disposable
  ) {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "rule-stage")
    self.builder = Behaviors.make(id, input: Void.self, subscribe: { _ in
      disposable()
    })
  }

  // MARK: Public

  @TreeActor
  public func act(for lifecycle: RuleLifecycle, with context: RuleContext) -> LifecycleResult {
    switch lifecycle {
    case .didStart:
      if let disposable = builder.scoped(manager: context.runtime.behaviorManager).behavior.value {
        disposable.stage(on: stage)
      }
    case .didUpdate:
      break
    case .willStop:
      stage.dispose()
    case .handleIntent:
      break
    }
    return .init()
  }

  @TreeActor
  public mutating func applyRule(with _: RuleContext) throws { }

  @TreeActor
  public mutating func removeRule(with _: RuleContext) throws { }

  @TreeActor
  public mutating func updateRule(
    from _: Self,
    with _: RuleContext
  ) throws { }

  // MARK: Private

  private var builder: Behaviors.SyncSingle<Void, any Disposable, Never>
  private let stage = DisposableStage()

}
