import Utilities

enum FieldCapture: Equatable {

  case dependency(Structure<any DependencyField>)
  case projection(Structure<any ProjectionField>)
  case route(Structure<any RouteField>)
  case scope(Structure<any ScopeField>)
  case value(Structure<any ValueField>, InitialValue)
  case unmanaged(Structure<Any>)

  // MARK: Lifecycle

  init(_ child: Mirror.Child, offset: Int) {
    let typeDescription = TypeDescription(
      description: "\(type(of: child.value))"
    )
    switch child.value {
    case let field as any DependencyField:
      self = .dependency(
        Structure(
          offset: offset,
          label: child.label,
          value: field,
          typeDescription: typeDescription
        )
      )
    case let field as any ProjectionField:
      self = .projection(
        Structure(
          offset: offset,
          label: child.label,
          value: field,
          typeDescription: typeDescription
        )
      )
    case let field as any RouteField:
      self = .route(
        Structure(
          offset: offset,
          label: child.label,
          value: field,
          typeDescription: typeDescription
        )
      )
    case let field as any ScopeField:
      self = .scope(
        Structure(
          offset: offset,
          label: child.label,
          value: field,
          typeDescription: typeDescription
        )
      )
    case let field as any ValueField:
      self = .value(
        Structure(
          offset: offset,
          label: child.label,
          value: field,
          typeDescription: typeDescription
        ),
        InitialValue(
          valueField: field
        )
      )
    default:
      self = .unmanaged(
        Structure(
          offset: offset,
          label: child.label,
          value: child.value,
          typeDescription: typeDescription
        )
      )
    }
  }

  // MARK: Internal

  struct Structure<T>: Equatable {
    let offset: Int
    let label: String?
    let value: T
    let typeDescription: TypeDescription

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.offset == rhs.offset
        && lhs.label == rhs.label
    }
  }

  struct InitialValue {
    let anyPayload: ValuePayload
    init(valueField: any ValueField) {
      self.anyPayload = try! ValuePayload(valueField.anyInitial)
    }
  }

  var label: String? {
    switch self {
    case .dependency(let structure):
      return structure.label
    case .projection(let structure):
      return structure.label
    case .route(let structure):
      return structure.label
    case .scope(let structure):
      return structure.label
    case .value(let structure, _):
      return structure.label
    case .unmanaged(let structure):
      return structure.label
    }
  }

  var type: FieldType {
    switch self {
    case .dependency:
      return .dependency
    case .projection:
      return .projection
    case .route:
      return .route
    case .scope:
      return .scope
    case .value:
      return .value
    case .unmanaged:
      return .unmanaged
    }
  }

  var typeDescription: TypeDescription {
    switch self {
    case .dependency(let structure):
      return structure.typeDescription
    case .projection(let structure):
      return structure.typeDescription
    case .route(let structure):
      return structure.typeDescription
    case .scope(let structure):
      return structure.typeDescription
    case .value(let structure, _):
      return structure.typeDescription
    case .unmanaged(let structure):
      return structure.typeDescription
    }
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.dependency(let structure1), .dependency(let structure2)):
      return structure1 == structure2
    case (.projection(let structure1), .projection(let structure2)):
      return structure1 == structure2
    case (.route(let structure1), .route(let structure2)):
      return structure1 == structure2
    case (.scope(let structure1), .scope(let structure2)):
      return structure1 == structure2
    case (.value(let structure1, _), .value(let structure2, _)):
      // NOTE: initial values are ignored to match SwiftUI behaviour.
      return structure1 == structure2
    case (.unmanaged(let structure1), .unmanaged(let structure2)):
      return structure1 == structure2
    default:
      return false
    }
  }

}
