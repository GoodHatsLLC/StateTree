import Disposable

// MARK: - AnyScope

@TreeActor
@_spi(Implementation)
public struct AnyScope: Hashable {

  // MARK: Lifecycle

  nonisolated init<N: Node>(scope: some Scoped<N>) {
    self.nid = scope.nid
    self.depth = scope.depth
    self.underlying = scope
    self.cuid = scope.cuid
    self.getNodeFunc = {
      scope.node
    }
    self.setNodeFunc = { anyNode in
      if let node = anyNode as? N {
        scope.node = node
      }
    }
  }

  // MARK: Public

  public let underlying: any Scoped

  public let cuid: CUID?

  public nonisolated static func == (lhs: AnyScope, rhs: AnyScope) -> Bool {
    lhs.nid == rhs.nid
  }

  public nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(nid)
  }

  public func own(_ disposable: some Disposable) { underlying.own(disposable) }

  // MARK: Internal

  let nid: NodeID
  let depth: Int
  let getNodeFunc: @TreeActor () -> any Node
  let setNodeFunc: @TreeActor (any Node) -> Void
}

// MARK: Scoping

extension AnyScope: Scoping {

  // MARK: Public

  public var valueFieldDependencies: Set<FieldID> { underlying.valueFieldDependencies }

  public func host<Behavior: BehaviorType>(behavior: Behavior, input: Behavior.Input) -> Behavior
    .Action?
  { underlying.host(behavior: behavior, input: input) }

  public func applyIntent(_ intent: Intent) -> StepResolutionInternal { underlying
    .applyIntent(intent)
  }

  // MARK: Internal

  var behaviorResolutions: [BehaviorResolution] {
    get async {
      await underlying.behaviorResolutions
    }
  }

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
  var isClean: Bool { underlying.isClean }
  var isFinished: Bool { underlying.isFinished }
  var record: NodeRecord { underlying.record }
  var requiresFinishing: Bool { underlying.requiresFinishing }
  var requiresReadying: Bool { underlying.requiresReadying }

  func stepTowardsReady() throws {
    try underlying.stepTowardsReady()
  }

  func stepTowardsFinished() throws {
    try underlying.stepTowardsFinished()
  }

  func markDirty(pending requirement: ExternalRequirement) {
    underlying.markDirty(pending: requirement)
  }

}
