// MARK: - Inject

public struct Inject<R: Rules>: Rules {

  // MARK: Lifecycle

  public init<Value>(
    _ path: WritableKeyPath<DependencyValues, Value>,
    _ value: Value,
    @RuleBuilder into rules: () -> R
  ) {
    self.dependenciesUpdateFunc = { initial in
      initial.injecting(path, value: value)
    }
    self.containedRules = rules()
  }

  // MARK: Public

  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
    switch lifecycle {
    case .didStart:
      break
    case .didUpdate:
      break
    case .willStop:
      break
    case .handleIntent:
      break
    }
    return .init()
  }

  public mutating func applyRule(with context: RuleContext) throws {
    let newContext = RuleContext(
      runtime: context.runtime,
      scope: context.scope,
      dependencies: dependenciesUpdateFunc(
        context.dependencies
      ),
      depth: context.depth
    )
    return try containedRules.applyRule(with: newContext)
  }

  public mutating func removeRule(with context: RuleContext) throws {
    let newContext = RuleContext(
      runtime: context.runtime,
      scope: context.scope,
      dependencies: dependenciesUpdateFunc(
        context.dependencies
      ),
      depth: context.depth
    )
    return try containedRules.removeRule(
      with: newContext
    )
  }

  public mutating func updateRule(
    from new: Self,
    with context: RuleContext
  ) throws {
    let newContext = RuleContext(
      runtime: context.runtime,
      scope: context.scope,
      dependencies: dependenciesUpdateFunc(
        context.dependencies
      ),
      depth: context.depth
    )
    return try containedRules.updateRule(from: new.containedRules, with: newContext)
  }

  public mutating func syncToState(with _: RuleContext) throws { }

  // MARK: Private

  private let dependenciesUpdateFunc: (DependencyValues) -> DependencyValues
  private var containedRules: R

}

extension Rules {
  public func injecting<Value>(
    _ path: WritableKeyPath<DependencyValues, Value>,
    _ value: Value
  ) -> Inject<some Rules> {
    Inject(path, value, into: { self })
  }
}
