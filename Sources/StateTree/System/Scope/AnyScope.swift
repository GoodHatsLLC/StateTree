import Behavior
import Disposable
import Emitter
import Intents

// MARK: - AnyScope

@TreeActor
@_spi(Implementation)
public struct AnyScope: Hashable {

  // MARK: Lifecycle

  nonisolated init<N: Node>(scope: some ScopeType<N>) {
    self.nid = scope.nid
    self.depth = scope.depth
    self.underlying = scope
    self.cuid = scope.cuid
    self.getNodeFunc = {
      scope.node
    }
    self.setNodeFunc = { node in
      if let node = node as? N {
        scope.node = node
      }
    }
  }

  // MARK: Public

  public let underlying: any ScopeType

  public let cuid: CUID?

  public nonisolated static func == (lhs: AnyScope, rhs: AnyScope) -> Bool {
    lhs.nid == rhs.nid
  }

  public nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(nid)
  }

  public func own(_ disposable: some Disposable) { underlying.own(disposable) }
  public func canOwn() -> Bool { underlying.canOwn() }

  // MARK: Internal

  let nid: NodeID
  let depth: Int
  let getNodeFunc: @TreeActor () -> any Node
  let setNodeFunc: @TreeActor (any Node) -> Void
}

// MARK: BehaviorScoping

extension AnyScope: BehaviorScoping {

  // MARK: Public

  public var valueFieldDependencies: Set<FieldID> { underlying.valueFieldDependencies }

  public func applyIntent(_ intent: Intent) -> IntentStepResolution { underlying
    .applyIntent(intent)
  }

  // MARK: Internal

  var node: any Node {
    get {
      getNodeFunc()
    }
    nonmutating set {
      setNodeFunc(newValue)
    }
  }

  var childScopes: [AnyScope] { underlying.childScopes }
  var dependencies: DependencyValues { underlying.dependencies }
  var initialCapture: NodeCapture { underlying.initialCapture }
  var isActive: Bool { underlying.isActive }
  var isStable: Bool { underlying.isStable }
  var record: NodeRecord { underlying.record }
  var requiresFinishing: Bool { underlying.requiresFinishing }
  var requiresReadying: Bool { underlying.requiresReadying }

  func stepTowardsReady() throws -> Bool {
    try underlying.stepTowardsReady()
  }

  func stepTowardsFinished() throws -> Bool {
    try underlying.stepTowardsFinished()
  }

  func markDirty(pending requirement: ExternalRequirement) {
    underlying.markDirty(pending: requirement)
  }

  func sendUpdateEvent() {
    underlying.sendUpdateEvent()
  }

}
