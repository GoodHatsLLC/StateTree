import Behavior
import Disposable

// MARK: - DidActivate

@MainActor
@propertyWrapper
public final class DidActivate<M: Model> {

  public init(wrappedValue: @escaping (_ model: M) -> Behavior<Void>) {
    self.wrappedValue = wrappedValue
    emit((self.wrappedValue, .didActivate))
  }

  public init(wrappedValue: @escaping (_ model: M) -> Task<Void, Error>) {
    self.wrappedValue = { model in wrappedValue(model).resultBehavior() }
    emit((self.wrappedValue, .didActivate))
  }

  public init(wrappedValue: @escaping (_ model: M) -> Void) {
    self.wrappedValue = { model in Behavior { wrappedValue(model) } }
    emit((self.wrappedValue, .didActivate))
  }

  public init(wrappedValue: @escaping (_ model: M) async -> Void) {
    self.wrappedValue = { model in Behavior { await wrappedValue(model) } }
    emit((self.wrappedValue, .didActivate))
  }

  public let wrappedValue: (_ model: M) -> Behavior<Void>

  private func emit(_ event: ModelAnnotation<M>) {
    ModelAnnotationCollector.endpoint.request(event: event)
  }

}
