import Disposable
import OrderedCollections
import TreeActor
@_spi(Implementation) import Utilities

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
        let node = try? runtime.getScope(for: id).node as? N
        assert(node?.cuid == id.cuid)
        return node
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
    let captures = capture()
    let scopes = try captures.compactMap { capture -> AnyScope? in
      guard let id = capture.cuid
      else {
        return nil
      }
      return try UninitializedNode(
        capture: capture,
        runtime: context.runtime
      )
      .initialize(
        as: N.self,
        depth: context.depth + 1,
        dependencies: context.dependencies,
        on: .init(
          fieldID: fieldID,
          identity: id,
          type: .list
        )
      ).connect().erase()
    }
    context.runtime.updateRoutedNodes(
      at: fieldID,
      to: .list(.init(nodeIDs: scopes.map(\.nid)))
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
    let currentlyRouted = context.runtime.getRoutedNodeSet(at: fieldID)?.ids ?? []
    let currentScopes = currentlyRouted.compactMap { id in
      let scope = try? context.runtime.getScope(for: id)
      assert(scope != nil)
      return scope
    }.indexed(by: \.cuid)
    let captures = new.capture()

    let scopes: [AnyScope] = try captures.compactMap { capture -> AnyScope? in
      guard let cuid = capture.cuid
      else {
        return nil
      }
      if let scope = currentScopes[cuid] {
//        scope.node = capture.anyNode
        if scope.node.cuid != cuid {
          scope.node = capture.anyNode
        }
        return scope
      } else {
        return try UninitializedNode(
          capture: capture,
          runtime: context.runtime
        )
        .initialize(
          as: N.self,
          depth: context.depth + 1,
          dependencies: context.dependencies,
          on: .init(
            fieldID: fieldID,
            identity: cuid,
            type: .list
          )
        ).connect().erase()
      }
    }
    context.runtime.updateRoutedNodes(
      at: fieldID,
      to: .list(.init(nodeIDs: scopes.map(\.nid)))
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

}
