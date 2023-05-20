import Disposable
import OrderedCollections
import TreeActor
@_spi(Implementation) import Utilities

// MARK: - RouteField

protocol RouteField<Router> {
  associatedtype Router: RouterType
  @TreeActor func connect(with connection: RouteConnection) -> RouteRecord
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
    guard let connection = inner.connection
    else { return nil }
    return connection
      .runtime
      .getRouteRecord(at: connection.fieldID)
  }

  var type: RouteType {
    Router.type
  }

  @TreeActor
  func connect(with connection: RouteConnection) -> RouteRecord {
    inner.connect(with: connection)
  }

  @_spi(Implementation)
  @TreeActor public var currentRoute: (record: RouteRecord, value: Router.Value)? {
    guard let connection = inner.connection
    else {
      return nil
    }
    guard
      let record = connection
        .runtime
        .getRouteRecord(at: connection.fieldID)
    else {
      return nil
    }
    guard let value = try? Router.value(for: record, in: connection.runtime)
    else {
      return nil
    }
    return (record, value)
  }

  @_spi(Implementation)
  @TreeActor public var endIndex: Int {
    guard
      let connection = inner.connection,
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
    currentRoute?.value ?? inner.defaultValue
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

  @_spi(Implementation) @TreeActor public var runtime: Runtime? { inner.connection?.runtime }

  // MARK: Private

  @TreeActor private final class Inner {

    // MARK: Lifecycle

    nonisolated init(defaultValue: Router.Value) {
      self.defaultValue = defaultValue
    }

    // MARK: Internal

    func connect(with connection: RouteConnection) -> RouteRecord {
      assert(self.connection == nil)
      self.connection = connection
      return routeToDefault()
    }

    func routeToDefault() -> RouteRecord {
      assert(self.connection != nil)
      // TODO: make default record
      fatalError()
    }

    let defaultValue: Router.Value

    private(set) var connection: RouteConnection?

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
        fieldID: inner.connection?.fieldID ?? .invalid
      ),
      to: self
    )
  }

  @TreeActor
  public func route(to builder: @escaping () -> Router.Value) -> Attach<Router> {
    Attach(
      router: .init(
        builder: builder,
        fieldID: inner.connection?.fieldID ?? .invalid
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
        fieldID: inner.connection?.fieldID ?? .invalid
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
        fieldID: inner.connection?.fieldID ?? .invalid
      ),
      to: self
    )
  }
}

extension Route {
  public init<A: Node>(wrappedValue: A? = nil)
    where Router == MaybeSingleRouter<A>
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
