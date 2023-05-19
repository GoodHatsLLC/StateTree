import Disposable
import OrderedCollections
import TreeActor
@_spi(Implementation) import Utilities

// MARK: - RouteField

protocol RouteField<Router> {
  associatedtype Router: RouterType
  @TreeActor var connection: RouteConnection? { get nonmutating set }
  var type: RouteType { get }
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

  public nonisolated init(defaultValue: Router.Value) {
    self.inner = .init(defaultValue: defaultValue)
  }

  // MARK: Public

  @TreeActor public var record: RouteRecord? {
    connection?
      .runtime
      .getRouteRecord(at: connection?.fieldID ?? .invalid)
  }

  public var type: RouteType {
    Router.routeType
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
        .getRouteRecord(at: connection.fieldID)
    else {
      return nil
    }
    guard let value = try? Router.value(for: idSet, in: connection.runtime)
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
        .getRouteRecord(at: connection.fieldID)
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
  @TreeActor public var wrappedValue: Router.Value {
    current?.value ?? inner.defaultValue
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

  // MARK: Internal

  @TreeActor var connection: RouteConnection? {
    get { inner.connection }
    nonmutating set { inner.connection = newValue }
  }

  // MARK: Private

  @TreeActor private final class Inner {

    // MARK: Lifecycle

    nonisolated init(defaultValue: Router.Value) {
      self.defaultValue = defaultValue
    }

    // MARK: Internal

    let defaultValue: Router.Value

    var connection: RouteConnection? {
      didSet {
        // TODO: set up default value
      }
    }

  }

  private let inner: Inner

}

extension Route where Router: OneRouterType {

  /// Attempt to route an arbitrary ``Node`` with a union router.
  ///
  /// This route overload will throw if the node's type isn't declared in the ``Route``
  /// defaultValueizer.
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
  @TreeActor
  public func route<U: NodeUnion>(to nodeBuilder: @escaping () -> U) throws -> some Rules
    where Router == UnionRouter<U>
  {
    Attach(
      router: .init(
        builder: nodeBuilder,
        fieldID: connection?.fieldID ?? .invalid
      ),
      to: self
    )
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
  public func route(to builder: @escaping () -> Router.Value) -> Attach<Router> {
    return Attach(
      router: .init(
        builder: builder,
        fieldID: connection?.fieldID ?? .invalid
      ),
      to: self
    )
  }
}

extension Route where Router: NRouterType {

  @TreeActor
  public func route<Data: Collection>(
    data: Data,
    builder: @escaping (_ datum: Data.Element) -> Router.NodeType
  )
    -> some Rules
    where Data.Element: Identifiable
  {
    let pairs = data.map { datum in
      (id: LSID(hashable: datum.id), datum: datum)
    }
    lazy var idMap = pairs.orderedIndexed(by: \.id).mapValues(\.datum)
    return Attach(
      router: .init(
        ids: idMap.keys,
        builder: { id in
          idMap[id].flatMap { datum in
            builder(datum)
          }!
        },
        fieldID: connection?.fieldID ?? .invalid
      ),
      to: self
    )
  }
}

extension Route where Router: NRouterType, Router.NodeType: Identifiable {
  @TreeActor
  public func route(builder: () -> [Router.NodeType]) -> some Rules {
    let nodes = builder()
    let pairs = nodes.map { node in
      (id: LSID(hashable: node.id), node: node)
    }
    lazy var idMap = pairs.indexed(by: \.id).mapValues(\.node)
    return Attach(
      router: .init(
        ids: OrderedSet(pairs.map(\.id)),
        builder: {
          idMap[$0]!
        },
        fieldID: connection?.fieldID ?? .invalid
      ),
      to: self
    )
  }
}

extension Route {
  public init<A: Node>(wrappedValue: A? = nil)
    where Router == MaybeRouter<A>
  { self.init(defaultValue: wrappedValue) }
}

extension Route {
  public init<A: Node>(wrappedValue: A)
    where Router == SingleRouter<A>
  { self.init(defaultValue: wrappedValue) }
}

extension Route {
  public init<A: Node, B: Node>(wrappedValue: Union.Two<A, B>)
    where Router == UnionRouter<Union.Two<A, B>>
  { self.init(defaultValue: wrappedValue) }
}

extension Route {
  public init<A: Node, B: Node, C: Node>(wrappedValue: Union.Three<A, B, C>)
    where Router == UnionRouter<Union.Three<A, B, C>>
  { self.init(defaultValue: wrappedValue) }
}

extension Route {
  public init<A: Node, B: Node>(wrappedValue: Union.Two<A, B>?)
    where Router == MaybeUnionRouter<Union.Two<A, B>>
  { self.init(defaultValue: wrappedValue) }
}

extension Route {
  public init<A: Node, B: Node, C: Node>(wrappedValue: Union.Three<A, B, C>?)
    where Router == MaybeUnionRouter<Union.Three<A, B, C>>
  { self.init(defaultValue: wrappedValue) }
}

extension Route {
  public init<A: Node>(wrappedValue: [A])
    where Router == ListRouter<A>
  { self.init(defaultValue: wrappedValue) }
}

// MARK: - RouteConnection

struct RouteConnection {
  let runtime: Runtime
  let fieldID: FieldID
}

// MARK: - UnenumeratedRouteError

struct UnenumeratedRouteError: Error { }
