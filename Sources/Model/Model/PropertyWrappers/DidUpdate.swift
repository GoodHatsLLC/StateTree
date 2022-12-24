import Behavior
import Disposable

// MARK: - DidUpdate

/// An annotation which executes in response to any model's state update.
///
///> Warning: This annotation is dangerous.
///> Any change made to the model state here will cause an infinite loop
///> unless the repeated changes converge to one final state.
@MainActor
@propertyWrapper
public final class DidUpdate<M: Model> {

  public init(wrappedValue: @escaping (_ model: M) -> Behavior<Void>) {
    self.wrappedValue = wrappedValue
    emit((self.wrappedValue, .didUpdate))
  }

  public init(wrappedValue: @escaping (_ model: M) -> Task<Void, Error>) {
    self.wrappedValue = { model in wrappedValue(model).resultBehavior() }
    emit((self.wrappedValue, .didUpdate))
  }

  public init(wrappedValue: @escaping (_ model: M) -> Void) {
    self.wrappedValue = { model in Behavior { wrappedValue(model) } }
    emit((self.wrappedValue, .didUpdate))
  }

  public init(wrappedValue: @escaping (_ model: M) async -> Void) {
    self.wrappedValue = { model in Behavior { await wrappedValue(model) } }
    emit((self.wrappedValue, .didUpdate))
  }

  public let wrappedValue: (_ model: M) -> Behavior<Void>

  private func emit(_ event: ModelAnnotation<M>) {
    ModelAnnotationCollector.endpoint.request(event: event)
  }

}
