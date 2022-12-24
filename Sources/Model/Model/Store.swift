import AccessTracker
import BehaviorInterface
import Dependencies
import Disposable
import Emitter
import Foundation
import Node
import Projection
import SourceLocation
import Utilities

// MARK: - Store

@MainActor
public struct Store<M: Model> {

  init(
    storage: _ModelStorage<M>
  ) {
    _storage = storage
    read = Reader(storage)
    modify = Modifier(storage)
    events = UpdateEmitter(storage)
  }

  public init(
    rootState: State
  ) {
    let projection = Projection(Access.ValueAccess(rootState))
    let storage = _ModelStorage<M>(
      projection: projection,
      map: .passthrough(),
      initial: projection.value
    )

    _storage = storage
    read = Reader(storage)
    modify = Modifier(storage)
    events = UpdateEmitter(storage)
  }

  public typealias State = M.State

  public let _storage: _ModelStorage<M>
  public let read: Reader<M>
  public let modify: Modifier<M>
  public let events: UpdateEmitter<M>
}

extension Store {

  public var dependencies: DependencyValues {
    _storage.dependencies
  }

  public var submodels: [any Model] {
    _storage.activeModel.value?.submodels ?? []
  }

}

extension Store {
  public var projection: Projector<M> {
    _storage.externalProjection()
  }

  public func transaction(_ writer: (_ state: inout State) -> Void) {
    _storage.write(writer)
  }

  public func proxy<T>(_ path: WritableKeyPath<State, T>) -> StoreValue<T> {
    StoreValue(projectedValue: .init(_storage, path: path))
  }

}

// MARK: BehaviorHost

extension Store {
  func produce<B: BehaviorType>(
    _ behavior: B,
    from location: SourceLocation
  )
    -> (() async throws -> B.Output)
  {
    _storage.produce(behavior: behavior, from: location)
  }

  func run<B: BehaviorType>(
    _ behavior: B,
    from location: SourceLocation
  ) {
    Task {
      try await _storage.produce(behavior: behavior, from: location)()
    }
  }

}
