// MARK: - Inject

public struct Inject<R: Rules>: Rules {

  // MARK: Lifecycle

  @_spi(Internal)
  public init(
    modification: @escaping (inout DependencyValues) -> Void,
    @RuleBuilder into rules: () -> R
  ) {
    self.dependenciesUpdateFunc = { dependencyValues in
      var copy = dependencyValues
      modification(&copy)
      return copy
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
  public func injecting(
    modifier: @escaping (_ dependencies: inout DependencyValues) -> Void
  ) -> Inject<some Rules> {
    Inject(modification: modifier, into: { self })
  }
}
