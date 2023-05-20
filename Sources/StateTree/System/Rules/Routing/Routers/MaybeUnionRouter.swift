import Disposable
import TreeActor

// MARK: - MaybeUnionRouter

public struct MaybeUnionRouter<U: NodeUnion>: OneRouterType {

  public static var type: RouteType {
    switch U.cardinality {
    case .two:
      return .maybeUnion2
    case .three:
      return .maybeUnion3
    }
  }

  public init(builder: @escaping () -> U?, fieldID: FieldID) {
    self.fieldID = fieldID
    self.builder = builder
  }

  public typealias Value = U?
  public let builder: () -> U?
  private let fieldID: FieldID
}

// MARK: RouterType

extension MaybeUnionRouter {

  // MARK: Public

  @_spi(Implementation)
  public static func value(
    for record: RouteRecord,
    in runtime: Runtime
  ) throws
    -> U?
  {
    try? U(record: record, runtime: runtime)
  }

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

  @TreeActor
  public mutating func applyRule(with context: RuleContext) throws {
    if let (union, initialized) = try initializeNode(context: context) {
      try start(
        union: union,
        initialized: initialized,
        on: context.runtime
      )
    }
  }

  @TreeActor
  public mutating func updateRule(
    from new: MaybeUnionRouter<U>,
    with context: RuleContext
  ) throws {
    guard let currentScopeContext = currentScopeContext(on: context.runtime)
    else {
      self = new
      return try applyRule(with: context)
    }
    guard let (newCapture, newUnion) = captureUnion()
    else {
      try removeRule(with: context)
      return
    }
    let currentScope = currentScopeContext.scope
    let currentIDSet = currentScopeContext.idSet

    if !newUnion.matchesCase(of: currentIDSet) || newCapture != currentScope.initialCapture {
      try removeRule(with: context)
      self = new
      try applyRule(with: context)
    } else {
      let existingManagedFieldsRecord = currentScope.record
      let replacementNode = try new.initialize(
        union: newUnion,
        capture: newCapture,
        context: context,
        withKnownRecord: existingManagedFieldsRecord
      )
      currentScope.node = replacementNode.node
    }
  }

  @TreeActor
  public mutating func removeRule(with context: RuleContext) throws {
    context.runtime.updateRouteRecord(at: fieldID, to: U.empty)
    assert(currentScope(on: context.runtime) == nil)
  }

  @TreeActor
  @_spi(Implementation)
  public func currentScope(on runtime: Runtime) -> AnyScope? {
    currentScopeContext(on: runtime)?.scope
  }

  // MARK: Internal

  @TreeActor
  func currentIDSet(on runtime: Runtime) -> RouteRecord? {
    runtime.getRouteRecord(at: fieldID)
  }

  @TreeActor
  func currentScopeContext(on runtime: Runtime) -> (idSet: RouteRecord, scope: AnyScope)? {
    guard let idSet = currentIDSet(on: runtime)
    else {
      return nil
    }
    assert(idSet.ids.count <= 1)
    return idSet.ids
      .first
      .flatMap { id in
        try? runtime.getScope(for: id)
      }
      .map { scope in
        (idSet, scope)
      }
  }

  // MARK: Private

  private func captureUnion() -> (NodeCapture, U)? {
    if let union = builder() {
      let capture = NodeCapture(union.anyNode)
      return (capture, union)
    } else {
      return nil
    }
  }

  @TreeActor
  private func initialize(
    union: U,
    capture: NodeCapture,
    context: RuleContext,
    withKnownRecord record: NodeRecord
  ) throws
    -> AnyInitializedNode
  {
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: context.runtime
    )
    guard let union = union as? any NodeUnionInternal
    else {
      throw UnionMissingInternalImplementationError()
    }
    let initialized = try union
      .initialize(
        from: uninitialized,
        depth: context.depth + 1,
        dependencies: context.dependencies,
        withKnownRecord: record
      )
    return initialized
  }

  @TreeActor
  private func initializeNode(context: RuleContext) throws
    -> (union: U, initialized: AnyInitializedNode)?
  {
    guard
      let (capture, publicUnion) = captureUnion(),
      let union = publicUnion as? any NodeUnionInternal
    else {
      throw UnionMissingInternalImplementationError()
    }
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: context.runtime
    )
    let initialized = try union.initialize(
      from: uninitialized,
      depth: context.depth + 1,
      dependencies: context.dependencies,
      fieldID: fieldID
    )
    return (publicUnion, initialized)
  }

  @TreeActor
  private mutating func start(
    union: U,
    initialized: AnyInitializedNode,
    on runtime: Runtime
  ) throws {
    let scope = try initialized.connect()
    let id = scope.nid
    let idSet = union.idSet(from: id)
    runtime.updateRouteRecord(at: fieldID, to: idSet)
  }

}
