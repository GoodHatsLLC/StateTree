import Behavior
import Disposable
import Emitter
import Intents
import TreeActor

// MARK: - ExternalRequirement

@_spi(Implementation)
public enum ExternalRequirement {
  case update
  case stop
}

// MARK: - ScopeType

@TreeActor
@_spi(Implementation)
public protocol ScopeType<N>: BehaviorScoping, Hashable {
  associatedtype N: Node
  nonisolated var nid: NodeID { get }
  nonisolated var depth: Int { get }
  var node: N { get }
  var requiresReadying: Bool { get }
  var requiresFinishing: Bool { get }
  var isActive: Bool { get }
  var isStable: Bool { get }
  var childScopes: [AnyScope] { get }
  var initialCapture: NodeCapture { get }
  var record: NodeRecord { get }
  var dependencies: DependencyValues { get }
  var valueFieldDependencies: Set<FieldID> { get }
  var didUpdateEmitter: AnyEmitter<Void, Never> { get }
  func sendUpdateEvent()
  func applyIntent(_ intent: Intent) -> IntentStepResolution
  func markDirty(pending: ExternalRequirement)
  func stepTowardsReady() throws -> Bool
  func stepTowardsFinished() throws -> Bool
  func stop() throws
  func disconnectSendingNotification()
  func erase() -> AnyScope
}
