import AccessTracker
import BehaviorInterface
import Bimapping
import Dependencies
import Disposable
import Emitter
import Foundation
import ModelInterface
import Node
import Projection
import SourceLocation
import Utilities

// MARK: - _ModelStorage

/// _ModelStorage backs the implementation of the Store
/// that is directly exposed to consumers.
///
/// _ModelStorage is a light wrapper containing implementation
/// details that are techncially public but don't need to clutter
/// up the Store API.
///
/// In cases where a Store is retained beyond the underlying
/// ActiveModel's lifetime and is queried for its state the
/// _ModelStorage provides last-good values.
/// (This happens during SwiftUI view updates when Bindings
/// to models that are in the process of being torn down are
/// queried.)
/// Similarly writes are dropped if the underlying ActiveModel
/// has been removed.
@MainActor
public struct _ModelStorage<M: Model>: Identifiable {

  init<Intermediate>(
    projection sourceProjection: Projection<Intermediate>,
    map: Bimapper<Intermediate, M.State>,
    initial: M.State
  ) {
    initialSourceProjection = sourceProjection
    cache = Ref(initial)
    let id = UUID()
    self.id = id
    createNodeFunc = { meta in
      meta.upstream
        .createDownstream(
          id: id,
          from: sourceProjection,
          map: map,
          initial: initial
        )
    }
  }

  public typealias State = M.State

  public let id: AnyHashable

  @MainActor
  final class Ref<V> {
    init(_ value: V) {
      self.value = value
    }

    var value: V
  }

  @usableFromInline
  let activeModel = ValueSubject<ActiveModel<M>?>(nil)

  private let cache: Ref<M.State>

  private let initialSourceProjection: any Accessor
  private let createNodeFunc: (StoreMeta) throws -> any StateNode

  private func createDownstream<Downstream: ModelState>(
    _: Projection<Downstream>,
    meta: StoreMeta
  ) throws -> Node<Downstream> {
    guard let node = try createNodeFunc(meta) as? Node<Downstream>
    else {
      throw IncorrectInputTypeError()
    }
    return node
  }

}

extension _ModelStorage {

  public var routeIdentity: SourcePath? {
    activeModel.value?.meta.routeIdentity
  }

  public var state: M.State {
    if let value = activeModel.value?.node.read() {
      cache.value = value
      return value
    } else {
      return cache.value
    }
  }

  public func unstartedSource() throws -> any Accessor {
    guard activeModel.value == nil
    else {
      throw ActiveModelError()
    }
    return initialSourceProjection
  }

}

// MARK: UpdateEmitter

extension _ModelStorage {

  @inlinable
  var routesDidChange: some Emitter<UUID> {
    activeModel
      .compactMap { $0 }
      .flatMapLatest { $0.routesDidChange }
  }

  @inlinable
  var stateDidChange: some Emitter<UUID> {
    activeModel
      .compactMap { $0 }
      .flatMapLatest { $0.stateDidChange }
  }

  @inlinable
  var observedStateDidChange: some Emitter<UUID> {
    activeModel
      .compactMap { $0 }
      .flatMapLatest { $0.observedStateDidChange }
  }

  @inlinable
  var subtreeDidChange: some Emitter<UUID> {
    activeModel
      .compactMap { $0 }
      .flatMapLatest { $0.subtreeDidChange }
  }

  @inlinable
  var observedSubtreeDidChange: some Emitter<UUID> {
    activeModel
      .compactMap { $0 }
      .flatMapLatest { $0.observedSubtreeDidChange }
  }

  @inlinable
  var didChangeValidity: some Emitter<Bool> {
    activeModel
      .map { $0 != nil }
      .removeDuplicates()
  }

  private var activeModelEmitter: some Emitter<ActiveModel<M>> {
    activeModel
      .compactMap { $0 }
  }

}

// MARK: Dependencies
extension _ModelStorage {
  var dependencies: DependencyValues {
    if let active = activeModel.value {
      return active.dependencies
    } else {
      DependencyValues.defaults.logger.error(
        message: "\(M.self) `dependencies` accessed when model was not started"
      )
      return .defaults
    }
  }
}

// MARK: _StateRecorder

extension _ModelStorage: _StateRecorder {

  public var _recorder: _Recorder<State> { _Recorder(self) }

  public func isValid() -> Bool {
    activeModel.value?.isValid() ?? false
  }

  func accumulateState(with accumulator: StateAccumulator) throws {
    if let active = activeModel.value {
      try active.accumulateState(with: accumulator)
    } else {
      throw InactiveModelError()
    }
  }

  func apply(state: State) throws {
    if let active = activeModel.value {
      active.apply(state: state)
    } else {
      throw InactiveModelError()
    }
  }

}

// MARK: Start Lifecycle
extension _ModelStorage {

  func start(
    model: M,
    meta: StoreMeta,
    annotations: [ModelAnnotation<M>]
  ) throws
    -> AnyDisposable
  {
    guard activeModel.value == nil
    else {
      throw ActiveModelError()
    }
    guard let node = try createNodeFunc(meta) as? Node<M.State>
    else {
      throw IncorrectInputTypeError()
    }
    let active = ActiveModel<M>(
      node: node,
      model: model,
      meta: meta
    )
    let stage = DisposalStage()

    do {
      try active
        .start(annotations: annotations)
        .stage(on: stage)
    } catch {
      activeModel.value = nil
      throw error
    }

    activeModel.value = active

    AnyDisposable {
      activeModel.value = nil
    }.stage(on: stage)

    return stage.erase()
  }
}

// MARK: I/O

extension _ModelStorage {

  func read<T: Equatable>(
    _ keyPath: KeyPath<State, T>
  )
    -> T
  {
    activeModel.value?.accessTracker.registerAccess(keyPath)

    if let value = activeModel.value?.node.read() {
      cache.value = value
      return value[keyPath: keyPath]
    } else {
      DependencyValues.defaults
        .logger
        .log(
          message:
            """
            Read from inactive model received cached value
            """,
          self,
          keyPath
        )
      return cache.value[keyPath: keyPath]
    }
  }

  func write(_ writer: (inout State) -> Void) {
    if let active = activeModel.value,
      active.isValid()
    {
      let original = active.node.read()
      var copy = original
      writer(&copy)
      if original == copy {
        return
      }
      _ = active.node.updateIfNeeded(state: copy)
    } else {
      DependencyValues.defaults
        .logger
        .warn(
          message:
            """
            Write to inactive store was discarded
            \(Thread.callStackSymbols.joined(separator: "\n"))
            """,
          self
        )
    }
  }

  func externalProjection() -> Projector<M> {
    Projector<M>(self)
  }

  func update(source projection: some Accessor) throws {
    if let active = activeModel.value {
      try active.update(source: projection)
    }
  }

}

// MARK: Long running behavior ownership
extension _ModelStorage {

  func stage<D: Disposable>(
    _ disposable: D
  ) {
    if let active = activeModel.value {
      active.stage(disposable)
    }
  }

  func produce<B: BehaviorType>(
    behavior: B,
    from location: SourceLocation
  )
    -> (() async throws -> B.Output)
  {
    if let active = activeModel.value {
      return active.run(behavior: behavior, from: location)
    }
    return { throw InactiveModelError() }
  }
}
