// @_spi(Implementation) import StateTreeBase
// import TreeActor
//
// @propertyWrapper
// public struct Reported<N: Node>: RouterAccess {
//  public typealias NodeType = N
//
//
//  // MARK: Lifecycle
//
//  public init(projectedValue: Reporter<N>) {
//    self.reporter = projectedValue
//    self.nodeID = projectedValue.scope.nid
//  }
//
//  @_spi(Implementation)
//  @TreeActor
//  public init(_ tree: NodeScope<N>) {
//    let reporter = Reporter(scope: tree)
//    self.reporter = reporter
//    self.nodeID = reporter.scope.nid
//  }
//
//  // MARK: Public
//
//  @_spi(Implementation) public var scope: NodeScope<N> {
//    reporter.scope
//  }
//
//  @_spi(Implementation) public var access: Reporter<N> {
//    reporter
//  }
//
//  public var wrappedValue: N {
//    scope.node
//  }
//
//  public var projectedValue: Reporter<N> {
//    reporter
//  }
//
//  @TreeActor
//  public func onChange(
//    subscriber: AnyObject,
//    _ callback: @escaping @Sendable @TreeActor () -> Void
//  ) {
//    reporter
//      .onChange(
//        subscriber: ObjectIdentifier(subscriber),
//        callback
//      )
//  }
//
//  @TreeActor
//  public func onChange(
//    subscriber: some Hashable,
//    _ callback: @escaping @Sendable @TreeActor () -> Void
//  ) {
//    reporter
//      .onChange(
//        subscriber: subscriber,
//        callback
//      )
//  }
//
//  @TreeActor
//  public func onStop(
//    subscriber: AnyObject,
//    _ callback: @escaping @Sendable @TreeActor () -> Void
//  ) {
//    reporter.onStop(
//      subscriber: ObjectIdentifier(subscriber),
//      callback
//    )
//  }
//
//  @TreeActor
//  public func onStop(
//    subscriber: some Hashable,
//    _ callback: @escaping @Sendable @TreeActor () -> Void
//  ) {
//    reporter.onStop(
//      subscriber: subscriber,
//      callback
//    )
//  }
//
//  @TreeActor
//  public func unregister(subscriber: AnyObject) {
//    reporter.unregister(
//      subscriber: ObjectIdentifier(subscriber)
//    )
//  }
//
//  @TreeActor
//  public func unregister(subscriber: some Hashable) {
//    reporter.unregister(
//      subscriber: subscriber
//    )
//  }
//
//  // MARK: Private
//
//  private let reporter: Reporter<N>
//  private let nodeID: NodeID
//
// }
