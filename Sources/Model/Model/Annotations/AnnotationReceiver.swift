// MARK: - AnnotationReceiver

public protocol AnnotationReceiver {
  associatedtype M: Model
  func receive(annotation: ModelAnnotation<M>)
}

extension AnnotationReceiver {
  func receive(any: Any) {
    if let event = any as? ModelAnnotation<M> {
      receive(annotation: event)
    }
  }
}
