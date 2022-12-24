import Behavior

// MARK: - ModelAnnotationType

public enum ModelAnnotationType {
  case didActivate
  case didUpdate
}

public typealias ModelAnnotation<M: Model> = (
  call: (_ model: M) -> Behavior<Void>, type: ModelAnnotationType
)
