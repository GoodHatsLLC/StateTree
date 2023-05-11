import Disposable
import TreeActor

// MARK: - SingleRouterType

public protocol SingleRouterType: RouterType { }

// MARK: - SingleRouter

public struct SingleRouter<N: Node>: RouterType {

  public typealias Value = N
  public init(container: Value, fieldID: FieldID) {
    self.container = container
    self.fieldID = fieldID
  }

  public let container: N
  private var node: N { container }
  private let fieldID: FieldID
}

// MARK: SingleRouterType

@_spi(Implementation)
extension SingleRouter: SingleRouterType {

  // MARK: Public

  @TreeActor
  public static func value(for record: RouteRecord, in runtime: Runtime) -> N? {
    if
      case .single(let single) = record,
      let single = single,
      let scope = try? runtime.getScope(for: single.id),
      let node = scope.node as? N
    {
      return node
    }
    return nil
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
    let initialized = try initialize(
      context: context
    )
    return try start(
      initialized: initialized,
      on: context.runtime
    )
  }

  @TreeActor
  public mutating func removeRule(with context: RuleContext) throws {
    context.runtime
      .updateRoutedNodes(at: fieldID, to: .single(nil))
  }

  @TreeActor
  public mutating func updateRule(
    from new: SingleRouter<N>,
    with context: RuleContext
  ) throws {
    guard let currentScope = currentScope(on: context.runtime)
    else {
      self = new
      return try applyRule(with: context)
    }
    let newCapture = new.capture()
    if newCapture != currentScope.initialCapture {
      try removeRule(with: context)
      self = new
      try applyRule(with: context)
    }
  }

  @TreeActor
  @_spi(Implementation)
  public func currentScope(on runtime: Runtime) -> AnyScope? {
    if
      let ids = runtime.getRoutedNodeSet(at: fieldID)?.ids,
      let id = ids.first
    {
      assert(ids.count == 1)
      return try? runtime.getScope(for: id)
    }
    return nil
  }

  // MARK: Private

  private func capture() -> NodeCapture {
    NodeCapture(node)
  }

  @TreeActor
  private func initialize(
    capture: NodeCapture,
    context: RuleContext,
    record: NodeRecord
  ) throws -> InitializedNode<N> {
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: context.runtime
    )
    let initialized = try uninitialized
      .initialize(
        as: N.self,
        depth: context.depth + 1,
        dependencies: context.dependencies,
        record: record
      )
    return initialized
  }

  @TreeActor
  private func initialize(context: RuleContext) throws -> InitializedNode<N> {
    let capture = capture()
    let uninitialized = UninitializedNode(
      capture: capture,
      runtime: context.runtime
    )
    let initialized = try uninitialized
      .initialize(
        as: N.self,
        depth: context.depth + 1,
        dependencies: context.dependencies,
        on: .init(
          fieldID: fieldID,
          identity: capture.anyNode.cuid,
          type: .single
        )
      )
    return initialized
  }

  @TreeActor
  private mutating func start(
    initialized: InitializedNode<N>,
    on runtime: Runtime
  ) throws {
    let scope = try initialized.connect().erase()
    runtime.updateRoutedNodes(
      at: fieldID,
      to: .single(
        .init(id: scope.nid)
      )
    )
    assert(scope == currentScope(on: runtime))
  }

}
