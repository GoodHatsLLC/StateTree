// MARK: - ModelAnnotationSink

public final class ModelAnnotationSink<M: Model>: AnnotationReceiver {

  public init() {}

  public var annotations: [ModelAnnotation<M>] = []

  public func receive(annotation: ModelAnnotation<M>) {
    annotations.append(annotation)
  }
}
