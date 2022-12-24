import Dependencies
import Node

@MainActor
struct InjectDependency<R: Routing>: Routing {

  init(
    into route: R,
    _ inject: @escaping @MainActor (_ current: DependencyValues) -> DependencyValues
  ) {
    self.inject = inject
    routing = route
  }

  var models: [any Model] {
    routing.models
  }

  mutating func attach(parentMeta: StoreMeta) throws -> Bool {
    let dependencies = inject(parentMeta.dependencies)
    let newMeta = parentMeta.copyEdit { copy in
      copy.dependencies = dependencies
    }
    return try routing.attach(parentMeta: newMeta)
  }

  mutating func detach() -> Bool {
    // pure detachment is cleanup and will not init models.
    routing.detach()
  }

  mutating func updateAttachment(
    from previous: Self,
    parentMeta: StoreMeta
  ) throws
    -> Bool
  {
    let dependencies = inject(parentMeta.dependencies)
    let newMeta = parentMeta.copyEdit { copy in
      copy.dependencies = dependencies
    }
    return try routing.updateAttachment(from: previous.routing, parentMeta: newMeta)
  }

  private var inject: @MainActor (DependencyValues) -> DependencyValues
  private var routing: R

}
