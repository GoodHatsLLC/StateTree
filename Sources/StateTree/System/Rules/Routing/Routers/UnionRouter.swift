import Disposable

// MARK: - UnionRouter

public struct UnionRouter<U: NodeUnion> {
  public typealias Value = U
  public init(
    container: U,
    fieldID: FieldID
  ) {
    self.container = container
    self.fieldID = fieldID
  }

  public let container: U
  private var union: U { container }
  private let fieldID: FieldID
}

// MARK: RouterType

extension UnionRouter: RouterType {

  // MARK: Public

  @_spi(Implementation)
  public static func value(
    for record: RouteRecord,
    in runtime: Runtime
  )
    -> U?
  {
    U(record: record, runtime: runtime)
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
    let (union, initialized) = try initializeNode(context: context)
    return try start(
      union: union,
      initialized: initialized,
      on: context.runtime
    )
  }

  @TreeActor
  public mutating func updateRule(
    from new: UnionRouter<U>,
    with context: RuleContext
  ) throws {
    guard let currentScopeContext = currentScopeContext(on: context.runtime)
    else {
      self = new
      return try applyRule(with: context)
    }
    let currentScope = currentScopeContext.scope
    let currentIDSet = currentScopeContext.idSet

    let (newCapture, newUnion) = captureUnion()
    if !newUnion.matchesCase(of: currentIDSet) || newCapture != currentScope.initialCapture {
      try removeRule(with: context)
      self = new
      try applyRule(with: context)
    } else {
      assertionFailure()
      let existingManagedFieldsRecord = currentScope.record
      let replacementNode = try new.initialize(
        union: newUnion,
        capture: newCapture,
        context: context,
        withKnownRecord: existingManagedFieldsRecord
      )
//      currentScope.node = replacementNode.node
    }
  }

  @TreeActor
  public mutating func removeRule(with context: RuleContext) throws {
    context.runtime.updateRoutedNodes(at: fieldID, to: U.empty)
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
    runtime.getRoutedNodeSet(at: fieldID)
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

  private func captureUnion() -> (NodeCapture, U) {
    let capture = NodeCapture(union.anyNode)
    return (capture, union)
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
    -> (union: U, initialized: AnyInitializedNode)
  {
    let (capture, publicUnion) = captureUnion()
    guard let union = publicUnion as? any NodeUnionInternal
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
    runtime.updateRoutedNodes(at: fieldID, to: idSet)
  }

}

// MARK: - NodeUnion

public protocol NodeUnion {
  var anyNode: any Node { get }
  @_spi(Implementation)
  init?(record: RouteRecord, runtime: Runtime)
  init?(asCaseContaining: some Node)
  static var empty: RouteRecord { get }
  func idSet(from: NodeID) -> RouteRecord
  func matchesCase(of: RouteRecord) -> Bool
}

// MARK: - NodeUnionInternal

protocol NodeUnionInternal: NodeUnion {
  func initialize(
    from: UninitializedNode,
    depth: Int,
    dependencies: DependencyValues,
    fieldID: FieldID
  ) throws -> AnyInitializedNode

  func initialize(
    from: UninitializedNode,
    depth: Int,
    dependencies: DependencyValues,
    withKnownRecord: NodeRecord
  ) throws -> AnyInitializedNode
}

// MARK: - Union

public enum Union { }

// MARK: - UnionMissingInternalImplementationError

struct UnionMissingInternalImplementationError: Error { }
