// MARK: - ModelAnnotationCollector

@MainActor
public final class ModelAnnotationCollector {

  public static let endpoint = ModelAnnotationCollector()

  public func using<Receiver: AnnotationReceiver, T>(
    receiver: Receiver,
    for lifetime: () throws -> T
  ) rethrows
    -> T
  {
    self.receiver = receiver
    defer { self.receiver = nil }
    return try lifetime()
  }

  func request<M: Model>(event: ModelAnnotation<M>) {
    receiver?.receive(any: event)
  }

  private var receiver: (any AnnotationReceiver)?

}
