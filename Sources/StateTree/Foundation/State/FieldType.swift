
// MARK: - MemberType

/// The type of a``Node`` fields managed by StateTree are one of these types.
enum FieldType: Codable, CaseIterable, LosslessStringConvertible {

  /// `@Dependency` (``Dependency``)  field on ``Node``.
  case dependency

  /// `@Projection` (``Projection``) field on ``Node``.
  case projection

  /// `@Route` (``Route``) field on a ``Node``.
  case route

  /// `@Scope` (``Scope``) field on a ``Node``.
  case scope

  /// `@Value` (``Value``) field on a ``Node``.
  case value

  /// A non-StateTree-managed field field on a ``Node``.
  ///
  /// e.g. a regular `let` or a `var` annotated without a StateTree property wrapper.
  case unmanaged

  // MARK: Lifecycle

  init?(_ description: String) {
    for type in FieldType.allCases {
      if type.description == description {
        self = type
        return
      }
    }
    return nil
  }

  // MARK: Internal

  var description: String {
    switch self {
    case .dependency:
      return "d"
    case .projection:
      return "p"
    case .route:
      return "r"
    case .scope:
      return "s"
    case .value:
      return "v"
    case .unmanaged:
      return "u"
    }
  }
}
