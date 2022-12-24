import Bimapping
import Dependencies
import Disposable
import Foundation
import Node
import Projection
import Utilities

// MARK: - Attach

public struct Attach<Intermediate, M: Model>: Routing {

  init(
    point: AttachmentPoint<M>,
    projection: Projection<Intermediate>,
    initial: M.State,
    stateMap: Bimapper<Intermediate, M.State>,
    model: @escaping (_ store: Store<M>) -> M
  ) {
    self.point = point
    let potential = PotentialModel(
      builder: {
        let store = Store<M>(
          storage: .init(
            projection: projection,
            map: stateMap,
            initial: initial
          )
        )
        return model(store)
      }
    )
    _potential = potential
    state = .potential(potential)
  }

  public var models: [any Model] {
    switch state {
    case .attached(let attachment):
      return [attachment.wrapper.model]
    case .potential:
      return []
    }
  }

  public mutating func attach(parentMeta: StoreMeta) throws -> Bool {
    guard case .potential(let potential) = state
    else {
      throw NoPotentialAttachmentError()
    }
    let wrapper = build(potential: potential, parentMeta: parentMeta)
    try attach(wrapper: wrapper, parentMeta: parentMeta)
    return true
  }

  public mutating func detach() -> Bool {
    guard case .attached = state
    else {
      // we didn't actually have anything to detach
      return false
    }
    state = .potential(_potential)
    point.detach()
    return true
  }

  public mutating func updateAttachment(
    from previous: Self,
    parentMeta: StoreMeta
  ) throws
    -> Bool
  {
    switch state {
    case .attached:
      throw ActiveModelError()
    case .potential(let potential):
      let wrapper = build(potential: potential, parentMeta: parentMeta)
      if case .attached(let attachment) = previous.state {
        try attachment
          .wrapper
          .model
          .store
          ._storage
          .update(source: wrapper.model.store._storage.unstartedSource())
        state = .attached(attachment)
        return false
      } else {
        try attach(wrapper: wrapper, parentMeta: parentMeta)
        return true
      }
    }
  }

  struct PotentialModel {
    let builder: @MainActor () -> M
  }

  struct ModelWrapper {
    let model: M
    let annotations: [ModelAnnotation<M>]
  }

  struct Attachment {
    let wrapper: ModelWrapper
    let disposable: AnyDisposable
  }

  enum State {
    case potential(PotentialModel)
    case attached(Attachment)
  }

  private let _potential: PotentialModel

  private let point: AttachmentPoint<M>
  private var state: State

  private func build(
    potential: PotentialModel,
    parentMeta: StoreMeta
  )
    -> ModelWrapper
  {
    let lifecycleEventProxy = ModelAnnotationSink<M>()
    let model = ModelAnnotationCollector
      .endpoint
      .using(receiver: lifecycleEventProxy) {
        DependencyStack
          .push(parentMeta.dependencies) {
            // the model made here is propagated
            // out of the dependency and lifecycle
            // context closures.
            potential.builder()
          }
      }

    return ModelWrapper(
      model: model,
      annotations: lifecycleEventProxy.annotations
    )
  }

  private mutating func attach(
    wrapper: ModelWrapper,
    parentMeta: StoreMeta
  ) throws {
    let newMeta = parentMeta.copyEdit { copy in
      copy.routeIdentity = .init(location: point.identity, upstream: copy.routeIdentity)
    }

    let disposable = try wrapper.model.store
      ._storage
      .start(
        model: wrapper.model,
        meta: newMeta,
        annotations: wrapper.annotations
      )

    try point.attach(model: wrapper.model)

    state = .attached(
      Attachment(
        wrapper: wrapper,
        disposable: disposable
      )
    )
  }

}
