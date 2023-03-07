import Disposable
import OrderedCollections

// MARK: - ListRouter

public struct ListRouter<N: Node> where N: Identifiable {

  public typealias Value = [N]
  public init(container: Value, fieldID: FieldID) {
    self.container = container
    self.fieldID = fieldID
  }

  public let container: [N]
  private let fieldID: FieldID
  private var nodes: [N] { container }
}

// MARK: RouterType

extension ListRouter: RouterType {
  @TreeActor
  @_spi(Implementation)
  public static func value(
    for record: RouteRecord,
    in runtime: Runtime
  ) -> [N]? {
    guard case .list(let list) = record, let list
    else {
      return nil
    }
    return list.nodeIDs
      .compactMap { id in
        try? runtime.getScope(for: id).node as? N
      }
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
      captures: capture(),
      context: context
    )
    try start(
      initializedList: initialized,
      on: context.runtime
    )
  }

  @TreeActor
  public mutating func removeRule(with context: RuleContext) throws {
    context.runtime
      .updateRoutedNodes(at: fieldID, to: .list(nil))
  }

  @TreeActor
  public mutating func updateRule(
    from new: ListRouter<N>,
    with context: RuleContext
  ) throws {
    let currentScopes = context.scope.childScopes
    let currentIDs = Set(currentScopes.compactMap(\.cuid))
    let captures = new.capture()
    let newIDs = Set(captures.compactMap(\.cuid))

    let continuedIdentifiableNodeIDs = currentIDs.intersection(newIDs)
    let startedIdentifiableNodeIDs = newIDs.subtracting(currentIDs)

    let continuedScopes = currentScopes.filter {
      guard let id = $0.cuid
      else {
        return false
      }
      return continuedIdentifiableNodeIDs.contains(id)
    }
    let newCaptures = captures.filter {
      guard let id = $0.cuid
      else {
        return false
      }
      return startedIdentifiableNodeIDs.contains(id)
    }

    let initialized = try initialize(
      captures: newCaptures,
      context: context
    )
    return try start(
      initializedList: initialized,
      continuing: continuedScopes,
      on: context.runtime
    )
  }

}

extension ListRouter {

  private func capture() -> [NodeCapture] {
    nodes.map(NodeCapture.init)
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
  private func initialize(
    captures: [NodeCapture],
    context: RuleContext
  ) throws -> [InitializedNode<N>] {
    let uninitializedList = captures.map { capture in
      UninitializedNode(
        capture: capture,
        runtime: context.runtime
      )
    }
    return try uninitializedList.map { uninitialized in
      try uninitialized
        .initialize(
          as: N.self,
          depth: context.depth + 1,
          dependencies: context.dependencies,
          on: .init(
            fieldID: fieldID,
            identity: uninitialized.capture.anyNode.cuid,
            type: .list
          )
        )
    }
  }

  @TreeActor
  private mutating func start(
    initializedList: [InitializedNode<N>],
    on runtime: Runtime
  ) throws {
    let scopes = try initializedList.map { initialized in
      try initialized.connect().erase()
    }
    runtime.updateRoutedNodes(
      at: fieldID,
      to: .list(.init(nodeIDs: scopes.map(\.nid)))
    )
  }

  @TreeActor
  private mutating func start(
    initializedList: [InitializedNode<N>],
    continuing: [AnyScope],
    on runtime: Runtime
  ) throws {
    let newScopes = try initializedList.map { initialized in
      try initialized.connect().erase()
    }
    let scopes = newScopes + continuing
    runtime.updateRoutedNodes(
      at: fieldID,
      to: .list(.init(nodeIDs: scopes.map(\.nid)))
    )
  }

}
