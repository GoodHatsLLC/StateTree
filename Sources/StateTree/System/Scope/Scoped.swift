import Disposable

// MARK: - Scoping

@TreeActor
public protocol Scoping {
  func host<Behavior: BehaviorType>(behavior: Behavior, input: Behavior.Input) -> Behavior.Action?
}

// MARK: - ExternalRequirement

@_spi(Implementation)
public enum ExternalRequirement {
  case rebuild
  case update
  case stop
}

// MARK: - Scoped

@TreeActor
@_spi(Implementation)
public protocol Scoped<N>: Scoping, Hashable {
  associatedtype N: Node
  nonisolated var nid: NodeID { get }
  nonisolated var uniqueIdentity: String? { get }
  nonisolated var depth: Int { get }
  var node: N { get nonmutating set }
  var requiresReadying: Bool { get }
  var requiresFinishing: Bool { get }
  var isActive: Bool { get }
  var isClean: Bool { get }
  var isFinished: Bool { get }
  var childScopes: [AnyScope] { get }
  var initialCapture: NodeCapture { get }
  var record: NodeRecord { get }
  var dependencies: DependencyValues { get }
  var valueFieldDependencies: Set<FieldID> { get }
  var behaviorResolutions: [BehaviorResolution] { get async }
  func applyIntent(_ intent: Intent) -> StepResolutionInternal
  func own(_ disposable: some Disposable)
  func stepTowardsReady() throws
  func markDirty(pending: ExternalRequirement)
  func stepTowardsFinished() throws
  func stop() throws
  func erase() -> AnyScope
}
