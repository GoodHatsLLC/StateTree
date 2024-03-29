import Behavior
import Disposable
import Emitter
import Intents
import OrderedCollections
import TreeActor

// MARK: - AnyScope

@TreeActor
@_spi(Implementation)
public struct AnyScope: Hashable {

  // MARK: Lifecycle

  nonisolated init(scope: some ScopeTypeInternal<some Node>) {
    self.nid = scope.nid
    self.depth = scope.depth
    self.underlying = scope
    self.getNodeFunc = {
      scope.node
    }
  }

  // MARK: Public

  @_spi(Implementation) public var underlyingScopeType: any ScopeType {
    underlying
  }

  public nonisolated static func == (lhs: AnyScope, rhs: AnyScope) -> Bool {
    lhs.nid == rhs.nid
  }

  public nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(nid)
  }

  public func own(_ disposable: some Disposable) { underlying.own(disposable) }
  public func canOwn() -> Bool { underlying.canOwn() }

  // MARK: Internal

  let underlying: any ScopeTypeInternal

  let nid: NodeID
  let depth: Int
  let getNodeFunc: @TreeActor () -> any Node
}

// MARK: StateSyncableScope, BehaviorScoping

extension AnyScope: StateSyncableScope, BehaviorScoping {

  // MARK: Public

  public var valueFieldDependencies: OrderedSet<FieldID> { underlying.valueFieldDependencies }

  public func applyIntent(_ intent: Intent) -> IntentStepResolution { underlying
    .applyIntent(intent)
  }

  // MARK: Internal

  var node: any Node {
    getNodeFunc()
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

  @TreeActor
  func stop() throws {
    try underlying.stop()
  }

  @TreeActor
  func syncToStateReportingCreatedScopes() throws -> [AnyScope] {
    try underlying.syncToStateReportingCreatedScopes()
  }

  func sendUpdateEvent() {
    underlying.sendUpdateEvent()
  }

  func disconnectSendingNotification() {
    underlying.disconnectSendingNotification()
  }

}
