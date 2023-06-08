import Behavior
import Disposable
import Emitter
import Foundation
import Intents
import OrderedCollections
import TreeActor
import Utilities

// MARK: - NodeScope

@_spi(Implementation)
public final class NodeScope<N: Node>: Equatable {

  // MARK: Lifecycle

  init(
    _ node: InitializedNode<N>,
    dependencies: DependencyValues,
    depth: Int
  ) {
    self.activeRules = nil
    self.dependencies = dependencies
    self.depth = depth
    self.nid = node.id
    self.initialCapture = node.initialCapture
    self.initialRecord = node.nodeRecord
    self.node = node.node
    self.runtime = node.runtime
    self.valueFieldDependencies = node.getValueDependencies()
    self.routerSet = node.routerSet
  }

  // MARK: Public

  public let node: N
  public let nid: NodeID
  public let depth: Int
  @_spi(Implementation) public var runtime: Runtime

  public nonisolated func erase() -> AnyScope {
    AnyScope(scope: self)
  }

  // MARK: Internal

  let dependencies: DependencyValues
  let valueFieldDependencies: OrderedSet<FieldID>
  let initialRecord: NodeRecord
  let initialCapture: NodeCapture

  let stage = DisposableStage()
  var activeRules: N.NodeRules?
  var state: ScopeUpdateLifecycle = .shouldStart
  let routerSet: RouterSet
  let didUpdateSubject = PublishSubject<Void, Never>()

  var context: RuleContext {
    .init(
      runtime: runtime,
      scope: erase(),
      dependencies: dependencies,
      depth: depth
    )
  }

}

// MARK: Hashable

extension NodeScope: Hashable {
  public nonisolated static func == (lhs: NodeScope<N>, rhs: NodeScope<N>) -> Bool {
    lhs.nid == rhs.nid
  }

  public nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(nid)
  }
}

// MARK: ScopeTypeInternal

extension NodeScope: ScopeTypeInternal {

  // MARK: Public

  public var didUpdateEmitter: AnyEmitter<Void, Never> { didUpdateSubject.erase() }
  public var isActive: Bool { activeRules != nil }
  public var childScopes: [AnyScope] { runtime.childScopes(of: nid) }

  // MARK: Internal

  @TreeActor var ancestors: [NodeID] {
    runtime.ancestors(of: nid) ?? []
  }

  @TreeActor var record: NodeRecord {
    runtime
      .getRecord(nid) ?? initialRecord
  }

}

// MARK: BehaviorScoping

extension NodeScope: BehaviorScoping {

  @TreeActor
  public func own(_ disposable: some Disposable) {
    if isActive {
      stage.stage(disposable)
    } else {
      disposable.dispose()
    }
  }

  @TreeActor
  public func canOwn() -> Bool {
    isActive
  }

}
