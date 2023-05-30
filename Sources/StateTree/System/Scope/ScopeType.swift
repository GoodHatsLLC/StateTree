import Behavior
import Disposable
import Emitter
import Intents
import TreeActor

// MARK: - ExternalRequirement

enum ExternalRequirement {
  case update
  case stop
}

// MARK: - ScopeType

/// `Scopes` are the runtime representation of ``Node``s.
@TreeActor
protocol ScopeType<N>: UpdatableScope, BehaviorScoping, Hashable {
  associatedtype N: Node
  nonisolated var nid: NodeID { get }
  nonisolated var depth: Int { get }
  var node: N { get }
  var isActive: Bool { get }
  var childScopes: [AnyScope] { get }
  var initialCapture: NodeCapture { get }
  var record: NodeRecord { get }
  var dependencies: DependencyValues { get }
  var valueFieldDependencies: Set<FieldID> { get }
  var didUpdateEmitter: AnyEmitter<Void, Never> { get }
  func erase() -> AnyScope
}
