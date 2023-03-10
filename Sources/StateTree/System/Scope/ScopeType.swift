import Disposable
import Emitter

// MARK: - ExternalRequirement

@_spi(Implementation)
public enum ExternalRequirement {
  case rebuild
  case update
  case stop
}

// MARK: - Scoping

public protocol Scoping {
  func own(_ disposable: some Disposable)
}

// MARK: - ScopeType

@TreeActor
@_spi(Implementation)
public protocol ScopeType<N>: Scoping, Hashable {
  associatedtype N: Node
  nonisolated var nid: NodeID { get }
  nonisolated var cuid: CUID? { get }
  nonisolated var depth: Int { get }
  var node: N { get nonmutating set }
  var requiresReadying: Bool { get }
  var requiresFinishing: Bool { get }
  var isActive: Bool { get }
  var isStable: Bool { get }
  var childScopes: [AnyScope] { get }
  var initialCapture: NodeCapture { get }
  var record: NodeRecord { get }
  var dependencies: DependencyValues { get }
  var valueFieldDependencies: Set<FieldID> { get }
  func resolveBehaviors() async -> [Behaviors.Resolved]
  func applyIntent(_ intent: Intent) -> StepResolutionInternal
  func markDirty(pending: ExternalRequirement)
  func stepTowardsReady() throws -> Bool
  func stepTowardsFinished() throws -> Bool
  func stop() throws
  func erase() -> AnyScope
}
