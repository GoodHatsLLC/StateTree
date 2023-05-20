// import Disposable
// import TreeActor
//
//// MARK: - MaybeSingleRouterType
//
// public protocol MaybeSingleRouterType: RouterType { }
//
//// MARK: - MaybeSingleRouter
//
// public struct MaybeSingleRouter<N: Node>: MaybeSingleRouterType, OneRouterType {
//
//  public static var type: RouteType { .maybeSingle }
//
//  public init(builder: @escaping () -> N?, fieldID: FieldID) {
//    self.builder = builder
//    self.fieldID = fieldID
//  }
//
//  public private(set) var builder: () -> N?
//
//  public typealias Value = N?
//
//  private let fieldID: FieldID
// }
//
//// MARK: MaybeSingleRouterType
//
// @_spi(Implementation)
// extension MaybeSingleRouter {
//
//  // MARK: Public
//
//  @TreeActor
//  public static func getValue(for record: RouteRecord, in runtime: Runtime) throws -> N? {
//    if
//      case .single(let single) = record,
//      let scope = try? runtime.getScope(for: single),
//      let node = scope.node as? N
//    {
//      return node
//    }
//    return nil
//  }
//
//  public func act(for lifecycle: RuleLifecycle, with _: RuleContext) -> LifecycleResult {
//    switch lifecycle {
//    case .didStart:
//      break
//    case .didUpdate:
//      break
//    case .willStop:
//      break
//    case .handleIntent:
//      break
//    }
//    return .init()
//  }
//
//  @TreeActor
//  public mutating func applyRule(with context: RuleContext) throws {
//    let initialized = try initialize(
//      context: context
//    )
//    if let initialized {
//      try start(
//        initialized: initialized,
//        on: context.runtime
//      )
//    } else {
//      context.runtime
//        .updateRouteRecord(at: fieldID, to: .maybeSingle(nil))
//    }
//  }
//
//  @TreeActor
//  public mutating func removeRule(with context: RuleContext) throws {
//    context.runtime
//      .updateRouteRecord(at: fieldID, to: .maybeSingle(nil))
//  }
//
//  @TreeActor
//  public mutating func updateRule(
//    from new: MaybeSingleRouter<N>,
//    with context: RuleContext
//  ) throws {
//    guard let currentScope = currentScope(on: context.runtime)
//    else {
//      self = new
//      return try applyRule(with: context)
//    }
//    let newCapture = new.capture()
//    if newCapture != currentScope.initialCapture {
//      try removeRule(with: context)
//      self = new
//      try applyRule(with: context)
//    }
//  }
//
//  @TreeActor
//  @_spi(Implementation)
//  public func currentScope(on runtime: Runtime) -> AnyScope? {
//    if
//      let ids = runtime.getRouteRecord(at: fieldID)?.ids,
//      let id = ids.first
//    {
//      assert(ids.count == 1)
//      return try? runtime.getScope(for: id)
//    }
//    return nil
//  }
//
//  // MARK: Private
//
//  private func capture() -> NodeCapture? {
//    builder().map { NodeCapture($0) }
//  }
//
//  @TreeActor
//  private func initialize(
//    capture: NodeCapture,
//    context: RuleContext,
//    record: NodeRecord
//  ) throws -> InitializedNode<N> {
//    let uninitialized = UninitializedNode(
//      capture: capture,
//      runtime: context.runtime
//    )
//    let initialized = try uninitialized
//      .initialize(
//        as: N.self,
//        depth: context.depth + 1,
//        dependencies: context.dependencies,
//        record: record
//      )
//    return initialized
//  }
//
//  @TreeActor
//  private func initialize(context: RuleContext) throws -> InitializedNode<N>? {
//    guard let capture = capture()
//    else {
//      return nil
//    }
//    let uninitialized = UninitializedNode(
//      capture: capture,
//      runtime: context.runtime
//    )
//    let initialized = try uninitialized
//      .initialize(
//        as: N.self,
//        depth: context.depth + 1,
//        dependencies: context.dependencies,
//        on: .init(
//          fieldID: fieldID,
//          identity: nil,
//          type: .maybeSingle
//        )
//      )
//    return initialized
//  }
//
//  @TreeActor
//  private mutating func start(
//    initialized: InitializedNode<N>,
//    on runtime: Runtime
//  ) throws {
//    let scope = try initialized.connect().erase()
//    runtime.updateRouteRecord(
//      at: fieldID,
//      to: .single(scope.nid)
//    )
//    assert(scope == currentScope(on: runtime))
//  }
//
// }
