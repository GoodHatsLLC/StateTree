import Disposable
import TreeActor

// MARK: - RouteField

protocol RouteField<Router> {
  associatedtype Router: RouterType
  @TreeActor var connection: RouteConnection? { get nonmutating set }
}

// MARK: - Route

/// A property wrapper used within a ``Node`` to launch a sub-node.
///
/// The sub-node will be active as long as ``route(to:)-2xtev`` is invoked
/// within the the host node's current active ``Rules`` — and the host node itself is active.
///
/// ```swift
/// struct MyNode: Node {
///
///   @Route(MySubNode.self) var myRoute
///   @Value var shouldRoute: Bool = true
///
///   var rules: some Rules {
///     if shouldRoute {
///       // The sub-node is created or kept active.
///       $myRoute.route { MySubNode() }
///     } else {
///       // The sub-node is torn down, stopping any
///       // of its own routed nodes and active rules.
///     }
///   }
/// }
/// ```
@propertyWrapper
public struct Route<Router: RouterType>: RouteField {

  // MARK: Lifecycle

  public nonisolated init() { }

  // MARK: Public

  @TreeActor public var record: RouteRecord? {
    connection?
      .runtime
      .getRoutedNodeSet(at: connection?.fieldID ?? .invalid)
  }

  @_spi(Implementation)
  @TreeActor public var current: (idSet: RouteRecord, value: Router.Value)? {
    guard let connection
    else {
      return nil
    }
    guard
      let idSet = connection
        .runtime
        .getRoutedNodeSet(at: connection.fieldID)
    else {
      return nil
    }
    guard let value = Router.value(for: idSet, in: connection.runtime)
    else {
      return nil
    }
    return (idSet, value)
  }

  @_spi(Implementation)
  @TreeActor public var endIndex: Int {
    guard
      let connection,
      let idSet = connection
        .runtime
        .getRoutedNodeSet(at: connection.fieldID)
    else {
      return 0
    }
    return idSet
      .ids
      .endIndex
  }

  /// The current routed ``Node``
  ///
  /// This value is optional — there is only a current routed node if a route
  /// is declared in the `Node's` `rules`:
  /// ```swift
  /// struct MyNode: Node {
  ///   @Route(MySubNode.self) var myRoute
  ///   var rules: some Rules {
  ///     $myRoute.route { MySubNode() }
  ///   }
  /// }
  /// ```
  @TreeActor public var wrappedValue: Router.Value? {
    current?.value
  }

  /// The `Route` itself, used for routing with ``route(to:)-2xtev``
  ///
  /// ```swift
  /// struct MyNode: Node {
  ///   @Route(MySubNode.self) var myRoute
  ///   var rules: some Rules {
  ///     $myRoute.route { MySubNode() }
  ///   }
  /// }
  /// ```
  public var projectedValue: Route<Router> { self }

  @_spi(Implementation) @TreeActor public var runtime: Runtime? { connection?.runtime }

  /// Attempt to route an arbitrary ``Node`` with a union router.
  ///
  /// This route overload will throw if the node's type isn't declared in the ``Route`` initializer.
  ///
  /// ```swift
  /// @Route(NodeOne.self, NodeTwo.self) var unionRoute
  ///
  /// var rules: some Rules {
  ///   // This will throw, creating a logging error rule.
  ///   try $unionRoute.route { NodeThree() }
  ///
  ///   // This will succeed.
  ///   try $unionRoute.route { NodeTwo() }
  /// }
  /// ```
  ///
  /// > Tip: Consider using the compile-time safe overload ``route(to:)-2xtev``.
  @TreeActor
  public func route<U: NodeUnion>(to nodeBuilder: @escaping () -> some Node) throws -> some Rules
    where Router == UnionRouter<U>
  {
    let node = nodeBuilder()
    let maybeValue = U(asCaseContaining: node)
    if let value: Router.Value = maybeValue {
      return Attach(
        router: .init(
          container: value,
          fieldID: connection?.fieldID ?? .invalid
        ),
        to: self
      )
    } else {
      throw UnenumeratedRouteError()
    }
  }

  /// Attempt to route an arbitrary ``Node`` with a union router.
  ///
  /// This route overload will throw if the node's type isn't declared in the ``Route`` initializer.
  ///
  /// ```swift
  /// @Route(NodeOne.self, NodeTwo.self) var unionRoute
  ///
  /// var rules: some Rules {
  ///   // This will throw, creating a logging error rule.
  ///   try $unionRoute.route(to: NodeThree())
  ///
  ///   // This will succeed.
  ///   try $unionRoute.route(to: NodeTwo())
  /// }
  /// ```
  ///
  /// > Tip: Consider using the compile-time safe overload ``route(to:)-2xtev``.
  @TreeActor
  public func route<U: NodeUnion>(to node: some Node) throws -> some Rules
    where Router == UnionRouter<U>
  {
    let maybeValue = U(asCaseContaining: node)
    if
      let value: Router.Value = maybeValue,
      let fieldID = connection?.fieldID
    {
      return Attach(
        router: .init(
          container: value,
          fieldID: fieldID
        ),
        to: self
      )
    } else {
      throw UnenumeratedRouteError()
    }
  }

  /// Route to the passed ``Node``, attaching it to the NodeTree ``Tree`` as a sub-node of the
  /// routing node.
  ///
  /// - Parameters:
  ///   - to: A closure returning a ``Node`` instance. If building a node for a union-type route, it
  /// should be
  ///   wrapped in a union type indicator. i.e. `.a(node)`, `.b(node)`, or `.c(node)`.
  ///
  /// A single-type `Route` doesn't require a wrapper. A union type `Route` requires a wrapper
  /// identifying the
  /// node as its first, second, or third type.—
  /// i.e. `.a(NodeOne())`, `.b(NodeTwo())`, `.c(NodeThree())` respectively.
  ///
  /// > Tip: Union routes can also be used with the throwing overload ``route(to:)-8f0z6``
  ///
  /// ```swift
  /// @Route(NodeOne.self) var singleRoute
  /// @Route(NodeOne.self, NodeTwo.self) var unionRoute
  ///
  /// var rules: some Rules {
  ///   // Working examples.
  ///   // These are compile-time safe.
  ///   $singleRoute.route { NodeOne() }
  ///   $unionRoute.route { .a(NodeTwo()) }
  ///
  ///   // This would fail to compile.
  ///   // $unionRoute { NodeOne() }
  ///
  ///   // This will call the throwing overload of route(to:)
  ///   // and succeed.
  ///   try $unionRoute.route { NodeOne() }
  ///
  ///   // This will call the throwing overload and fail, creating
  ///   // an UnenumeratedRouteError and returning a logging Error rule.
  ///   try $unionRoute.route { NodeThree() }
  /// }
  /// ```
  @TreeActor
  public func route(to containerBuilder: () -> Router.Value) -> Attach<Router> {
    route(to: containerBuilder())
  }

  /// Route to the passed ``Node``, attaching it to the NodeTree ``Tree`` as a sub-node of the
  /// routing node.
  ///
  /// > Parameters:
  /// - to: The node to route — within the wrapper required by the route if required.
  ///
  /// A single-type `Route` doesn't require a wrapper. A union type `Route` requires a wrapper
  /// identifying the
  /// node as its first, second, or third type.—
  /// i.e. `.a(NodeOne())`, `.b(NodeTwo())`, `.c(NodeThree())` respectively.
  ///
  /// > Tip: Union routes can also be used with the throwing overload ``route(to:)-8f0z6``
  ///
  /// ```swift
  /// @Route(NodeOne.self) var singleRoute
  /// @Route(NodeOne.self, NodeTwo.self) var unionRoute
  ///
  /// var rules: some Rules {
  ///   // Working examples.
  ///   // These are compile-time safe.
  ///   $singleRoute.route(to: NodeOne())
  ///   $unionRoute.route(to: .a(NodeTwo()))
  ///
  ///   // This would fail to compile.
  ///   // $unionRoute(to: NodeOne())
  ///
  ///   // This will call the throwing overload of route(to:)
  ///   // and succeed.
  ///   try $unionRoute.route(to: NodeOne())
  ///
  ///   // This will call the throwing overload and fail, creating
  ///   // an UnenumeratedRouteError and returning a logging Error rule.
  ///   try $unionRoute.route(to: NodeThree())
  /// }
  /// ```
  @TreeActor
  public func route(to container: Router.Value) -> Attach<Router> {
    Attach(
      router: .init(
        container: container,
        fieldID: connection?.fieldID ?? .invalid
      ),
      to: self
    )
  }

  /// TODO: replace this with a data oriented list routing.
  @TreeActor
  public func route<N: Node>(to nodes: [N]) -> some Rules
    where N: Identifiable, Router == ListRouter<N>
  {
    Attach(
      router: .init(container: nodes, fieldID: connection?.fieldID ?? .invalid),
      to: self
    )
  }

  // MARK: Internal

  @TreeActor var connection: RouteConnection? {
    get { inner.connection }
    nonmutating set { inner.connection = newValue }
  }

  // MARK: Private

  @TreeActor private final class Inner {

    // MARK: Lifecycle

    nonisolated init() { }

    // MARK: Internal

    var connection: RouteConnection?

  }

  private let inner = Inner()

}

extension Route {
  public init<A: Node>(_: A.Type)
    where Router == SingleRouter<A>
  { self.init() }
}

extension Route {
  public init<A: Node, B: Node>(_: A.Type, _: B.Type)
    where Router == UnionRouter<Union.Two<A, B>>
  { self.init() }
}

extension Route {
  public init<A: Node, B: Node, C: Node>(_: A.Type, _: B.Type, _: C.Type)
    where Router == UnionRouter<Union.Three<A, B, C>>
  { self.init() }
}

extension Route {
  public init<A: Node>(_: [A].Type)
    where Router == ListRouter<A>
  { self.init() }
}

// MARK: - RouteConnection

struct RouteConnection {
  let runtime: Runtime
  let fieldID: FieldID
}

// MARK: - UnenumeratedRouteError

struct UnenumeratedRouteError: Error { }
