@_spi(Implementation) import StateTree

@TreeActor
@propertyWrapper
public struct Reported<N: Node>: NodeAccess {

  // MARK: Lifecycle

  public init(projectedValue: Reported<N>) {
    self = projectedValue
  }

  init(reporter: Reporter<N>) {
    self.reporter = reporter
    self.nodeID = reporter.scope.id
  }

  public init(tree: TreeLifetime<N>) {
    let reporter = Reporter(root: tree)
    self.reporter = reporter
    self.nodeID = reporter.scope.id
  }

  // MARK: Public

  @_spi(Implementation) public var scope: NodeScope<N> {
    reporter.scope
  }

  public var wrappedValue: N {
    scope.node
  }

  public var projectedValue: Reported<N> {
    self
  }

  public func onChange(
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    reporter
      .onChange(
        of: nodeID,
        callback
      )
  }

  // MARK: Internal

  func onCancel(
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    reporter.onCancel(callback)
  }

  func onStop(
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    reporter.onStop(callback)
  }

  // MARK: Private

  private let reporter: Reporter<N>
  private let nodeID: NodeID

}
