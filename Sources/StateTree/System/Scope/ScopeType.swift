import Behavior
import Disposable
import Emitter
import Intents
import OrderedCollections
import TreeActor

// MARK: - ExternalRequirement

enum ExternalRequirement {
  case update
  case stop
}

// MARK: - ScopeType

public protocol ScopeType<N>: Hashable {
  associatedtype N: Node
  nonisolated var nid: NodeID { get }
  var node: N { get }
}

// MARK: - ScopeTypeInternal

/// `Scopes` are the runtime representation of ``Node``s.
@TreeActor
protocol ScopeTypeInternal<N>: ScopeType, UpdatableScope, StateSyncableScope, BehaviorScoping,
  Hashable
{
  nonisolated var nid: NodeID { get }
  nonisolated var depth: Int { get }
  var node: N { get }
  var isActive: Bool { get }
  var childScopes: [AnyScope] { get }
  var initialCapture: NodeCapture { get }
  var record: NodeRecord { get }
  var dependencies: DependencyValues { get }
  var valueFieldDependencies: OrderedSet<FieldID> { get }
  var didUpdateEmitter: AnyEmitter<Void, Never> { get }
  func erase() -> AnyScope
}
