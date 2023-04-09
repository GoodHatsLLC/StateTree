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
    self.nodeID = reporter.scope.nid
  }

  public init(tree _: Tree<N>) {
    fatalError()
//    let reporter = Reporter(root: tree)
//    self.reporter = reporter
//    self.nodeID = reporter.scope.nid
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
    subscriber: AnyObject,
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    reporter
      .onChange(
        owner: ObjectIdentifier(subscriber),
        callback
      )
  }

  public func onStop(
    subscriber: AnyObject,
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    reporter.onStop(
      owner: ObjectIdentifier(subscriber),
      callback
    )
  }

  public func unregister(subscriber: AnyObject) {
    reporter.unregister(
      subscriber: ObjectIdentifier(subscriber)
    )
  }

  // MARK: Private

  private let reporter: Reporter<N>
  private let nodeID: NodeID

}
