enum StateChangeMetadata {
  init?(value fieldID: FieldID) {
    if fieldID.type == .value {
      self = .value(field: fieldID)
    } else {
      return nil
    }
  }

  init?(projection field: FieldID, source: ProjectionSource) {
    if
      field.type == .projection,
      case .valueField(let valueField) = source
    {
      self = .projection(field: field, value: valueField)
    } else {
      return nil
    }
  }

  case value(field: FieldID)
  case projection(field: FieldID, value: FieldID)
}
