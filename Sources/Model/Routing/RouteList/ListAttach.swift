import Bimapping
import Dependencies
import Disposable
import Foundation
import Node
import Projection
import Utilities

// MARK: - ListAttach

@MainActor
public struct ListAttach<M: Model, I: Identifiable>: Routing {

  init(
    point: ListAttachmentPoint<M>,
    collection: Projection<[I]>,
    into value: M.State,
    with map: Bimapper<I, M.State>,
    model: @escaping (_ item: I, _ store: Store<M>) -> M
  ) {
    self.point = point

    let items = collection.value
    let inputs =
      items
      .enumerated()
      .map { offset, item in

        let access = Transform.Stateful(
          map: map,
          upstream: collection[offset],
          downstream: Access.ValueAccess(value),
          isValid: { _ in
            items.startIndex <= offset && offset < items.endIndex
          }
        )
        let projection = collection[offset]
          .map(access)
        let store = Store<M>(
          storage: .init(
            projection: projection,
            map: .passthrough(),
            initial: projection.value
          )
        )
        return (store: store, item: item)
      }

    let potential = PotentialModels(
      builders:
        inputs
        .map { store, item in
          {
            (
              key: AnyHashable(item.id),
              model: model(item, store)
            )
          }
        }
    )
    _potential = potential
    state = .potential(potential)
  }

  init(
    point: ListAttachmentPoint<M>,
    collection: Projection<[I]>,
    model: @escaping (_ item: I, _ store: Store<M>) -> M
  ) where I == M.State {
    self.point = point

    let items = collection.value
    let inputs =
      items
      .enumerated()
      .map { offset, item in
        let store = Store<M>(
          storage: .init(
            projection: collection[offset],
            map: .passthrough(),
            initial: collection[offset].value
          )
        )
        return (store: store, item: item)
      }

    let potential = PotentialModels(
      builders:
        inputs
        .map { store, item in
          {
            (
              key: AnyHashable(item.id),
              model: model(item, store)
            )
          }
        }
    )
    _potential = potential
    state = .potential(potential)
  }

  public var models: [any Model] {
    switch state {
    case .attached(let attachments):
      return attachments.map(\.wrapper.model)
    case .potential:
      return []
    }
  }

  public mutating func attach(parentMeta: StoreMeta) throws -> Bool {
    guard case .potential(let potential) = state
    else {
      throw NoPotentialAttachmentError()
    }
    let wrappers = build(potential: potential, parentMeta: parentMeta)
    let attachment = try start(wrappers: wrappers, parentMeta: parentMeta)
    state = .attached(attachment)
    point.models = attachment.map(\.wrapper.model)
    return true
  }

  public mutating func detach() -> Bool {
    guard case .attached = state
    else {
      // we didn't actually have anything to detach
      return false
    }
    state = .potential(_potential)
    point.models = []
    return true
  }

  public mutating func updateAttachment(
    from previous: Self,
    parentMeta: StoreMeta
  ) throws
    -> Bool
  {
    guard case .attached(let prev) = previous.state
    else {
      return try attach(parentMeta: parentMeta)
    }
    switch state {
    case .attached:
      throw ActiveModelError()
    case .potential(let potential):
      let wrappers = build(potential: potential, parentMeta: parentMeta)
      let newKeys = Set(wrappers.map(\.key))
      let prevKeys = Set(prev.map(\.wrapper.key))
      let startKeys = newKeys.subtracting(prevKeys)
      let stopKeys = prevKeys.subtracting(newKeys)
      let continueKeys = newKeys.intersection(prevKeys)
      let newIndex = wrappers.reduce(into: [AnyHashable: ModelWrapper]()) {
        partialResult, wrapper in
        partialResult[wrapper.key] = wrapper
      }
      let continueAttachments =
        prev
        .filter { continueKeys.contains($0.wrapper.key) }
      let startWrappers = startKeys.compactMap { newIndex[$0] }

      for cont in continueAttachments {
        let key = cont.wrapper.key
        guard let new = newIndex[key]
        else {
          continue
        }
        let newSource = try new.model.store._storage.unstartedSource()
        try cont.wrapper.model.store._storage.update(source: newSource)
      }

      let newAttachments = try start(wrappers: startWrappers, parentMeta: parentMeta)

      let allAttachments = continueAttachments + newAttachments

      point.models = allAttachments.map(\.wrapper.model)
      state = .attached(allAttachments)
      return (newKeys.count + stopKeys.count) > 0
    }
  }

  struct PotentialModels {
    let builders: [@MainActor () -> (key: AnyHashable, model: M)]
  }

  struct ModelWrapper {
    let key: AnyHashable
    let model: M
    let events: [ModelAnnotation<M>]
  }

  struct Attachment {
    let wrapper: ModelWrapper
    let disposable: AnyDisposable
  }

  enum State {
    case potential(PotentialModels)
    case attached([Attachment])
  }

  private let _potential: PotentialModels

  private let point: ListAttachmentPoint<M>
  private var state: State

  private func build(
    potential: PotentialModels,
    parentMeta: StoreMeta
  ) -> [ModelWrapper] {
    DependencyStack
      .push(parentMeta.dependencies) {
        potential.builders
          .map { builder in

            let lifecycleEventProxy = ModelAnnotationSink<M>()
            let built = ModelAnnotationCollector
              .endpoint
              .using(receiver: lifecycleEventProxy) {
                // the model made here is propagated
                // out of the dependency and lifecycle
                // context closures.
                builder()
              }
            return ModelWrapper(
              key: built.key,
              model: built.model,
              events: lifecycleEventProxy.annotations
            )
          }
      }
  }

  private mutating func start(
    wrappers: [ModelWrapper],
    parentMeta: StoreMeta
  ) throws -> [Attachment] {
    try wrappers
      .map { wrapper in

        let newMeta = parentMeta.copyEdit { copy in
          copy.routeIdentity = .init(
            location: point.identity,
            indexHashable: wrapper.key,
            upstream: copy.routeIdentity
          )
        }

        let disposable = try wrapper.model.store
          ._storage
          .start(
            model: wrapper.model,
            meta: newMeta,
            annotations: wrapper.events
          )

        return Attachment(wrapper: wrapper, disposable: disposable)
      }
  }

}
