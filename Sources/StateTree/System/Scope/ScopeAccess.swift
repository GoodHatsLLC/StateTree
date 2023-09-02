import TreeActor
import Utilities

// MARK: - ScopeAccess

@TreeActor
public protocol ScopeAccess {
  associatedtype NodeType: Node
  @_spi(Implementation) var scope: NodeScope<NodeType> { get }
}

// MARK: - ScopeAccessor

@TreeActor
private struct ScopeAccessor {
  init(field: some RouteFieldType, runtime: Runtime) throws {
    self.fieldID = try field.fieldID.orThrow(UninitializedRouteError())
    self.runtime = runtime
  }

  let fieldID: FieldID
  let runtime: Runtime

  func getRouteID(identity: LSID? = nil) -> RouteID {
    .init(fieldID: fieldID, identity: identity)
  }

  func getRecord() throws -> RouteRecord {
    try runtime.getRouteRecord(at: fieldID).orThrow(MissingRecordError())
  }

  func knownScope(id nodeID: NodeID) throws -> any ScopeType {
    try runtime.getScope(for: nodeID).underlyingScopeType
  }

  func assumeScope(identity: LSID? = nil) throws -> any ScopeType {
    try runtime.getScope(at: getRouteID(identity: identity)).underlyingScopeType
  }

  func maybeScope(identity: LSID? = nil) -> (any ScopeType)? {
    try? runtime.getScope(at: getRouteID(identity: identity)).underlyingScopeType
  }

}

extension ScopeType {
  func containing<N: Node>(_: N.Type) throws -> NodeScope<N> {
    try (self as? NodeScope<N>).orThrow(BadScopeError())
  }
}

@_spi(Implementation)
extension ScopeAccess {
  public func access<SubNode: Node>(
    via path: KeyPath<NodeType, Route<SingleRouter<SubNode>>>
  ) throws -> NodeScope<SubNode> {
    try ScopeAccessor(
      field: scope.node[keyPath: path],
      runtime: scope.runtime
    )
    .assumeScope()
    .containing(SubNode.self)
  }

  public func access<SubNode: Node>(
    via path: KeyPath<NodeType, Route<MaybeSingleRouter<SubNode>>>
  ) throws -> NodeScope<SubNode>? {
    try ScopeAccessor(
      field: scope.node[keyPath: path],
      runtime: scope.runtime
    )
    .maybeScope()?
    .containing(SubNode.self)
  }

  public func access<SubNodeA: Node, SubNodeB: Node>(
    via path: KeyPath<NodeType, Route<Union2Router<SubNodeA, SubNodeB>>>
  ) throws -> Union2<NodeScope<SubNodeA>, NodeScope<SubNodeB>> {
    let accessor = try ScopeAccessor(
      field: scope.node[keyPath: path],
      runtime: scope.runtime
    )
    guard case .union2(let union2) = try accessor.getRecord()
    else {
      throw BadRecordError()
    }
    switch union2 {
    case .a(let nodeID):
      return try .a(accessor.knownScope(id: nodeID).containing(SubNodeA.self))
    case .b(let nodeID):
      return try .b(accessor.knownScope(id: nodeID).containing(SubNodeB.self))
    }
  }

  public func access<SubNodeA: Node, SubNodeB: Node>(
    via path: KeyPath<NodeType, Route<MaybeUnion2Router<SubNodeA, SubNodeB>>>
  ) throws -> Union2<NodeScope<SubNodeA>, NodeScope<SubNodeB>>? {
    let accessor = try ScopeAccessor(
      field: scope.node[keyPath: path],
      runtime: scope.runtime
    )
    guard case .maybeUnion2(let union2) = try accessor.getRecord()
    else {
      throw BadRecordError()
    }
    guard let union2 = union2
    else {
      return nil
    }
    switch union2 {
    case .a(let nodeID):
      return try .a(accessor.knownScope(id: nodeID).containing(SubNodeA.self))
    case .b(let nodeID):
      return try .b(accessor.knownScope(id: nodeID).containing(SubNodeB.self))
    }
  }

  public func access<SubNodeA: Node, SubNodeB: Node, SubNodeC: Node>(
    via path: KeyPath<NodeType, Route<Union3Router<SubNodeA, SubNodeB, SubNodeC>>>
  ) throws -> Union3<NodeScope<SubNodeA>, NodeScope<SubNodeB>, NodeScope<SubNodeC>> {
    let accessor = try ScopeAccessor(
      field: scope.node[keyPath: path],
      runtime: scope.runtime
    )
    guard case .union3(let union3) = try accessor.getRecord()
    else {
      throw BadRecordError()
    }
    switch union3 {
    case .a(let nodeID):
      return try .a(accessor.knownScope(id: nodeID).containing(SubNodeA.self))
    case .b(let nodeID):
      return try .b(accessor.knownScope(id: nodeID).containing(SubNodeB.self))
    case .c(let nodeID):
      return try .c(accessor.knownScope(id: nodeID).containing(SubNodeC.self))
    }
  }

  public func access<SubNodeA: Node, SubNodeB: Node, SubNodeC: Node>(
    via path: KeyPath<NodeType, Route<MaybeUnion3Router<SubNodeA, SubNodeB, SubNodeC>>>
  ) throws -> Union3<NodeScope<SubNodeA>, NodeScope<SubNodeB>, NodeScope<SubNodeC>>? {
    let accessor = try ScopeAccessor(
      field: scope.node[keyPath: path],
      runtime: scope.runtime
    )
    guard case .maybeUnion3(let union3) = try accessor.getRecord()
    else {
      throw BadRecordError()
    }
    guard let union3 = union3
    else {
      return nil
    }
    switch union3 {
    case .a(let nodeID):
      return try .a(accessor.knownScope(id: nodeID).containing(SubNodeA.self))
    case .b(let nodeID):
      return try .b(accessor.knownScope(id: nodeID).containing(SubNodeB.self))
    case .c(let nodeID):
      return try .c(accessor.knownScope(id: nodeID).containing(SubNodeC.self))
    }
  }

  public func access<SubNode: Node>(
    via path: KeyPath<NodeType, Route<ListRouter<SubNode>>>
  ) throws -> DeferredList<Int, NodeScope<SubNode>, any Error> {
    let accessor = try ScopeAccessor(
      field: scope.node[keyPath: path],
      runtime: scope.runtime
    )
    let record = try accessor.getRecord()
    guard record.type == .list
    else {
      throw BadRecordError()
    }
    let nodeIDs = record.ids
    return DeferredList(indices: nodeIDs.indices) { index in
      guard nodeIDs.count > index, index >= 0
      else {
        return .failure(BadRecordError())
      }
      do {
        let value = try accessor
          .knownScope(id: nodeIDs[index])
          .containing(SubNode.self)
        return .success(value)
      } catch {
        return .failure(error)
      }
    }
  }
}

// MARK: - UninitializedRouteError

struct UninitializedRouteError: Error { }

// MARK: - MissingRecordError

struct MissingRecordError: Error { }

// MARK: - BadRecordError

struct BadRecordError: Error { }

// MARK: - BadScopeError

struct BadScopeError: Error { }
