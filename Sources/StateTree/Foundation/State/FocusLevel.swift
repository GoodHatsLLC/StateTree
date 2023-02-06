public enum FocusLevel: Int, TreeState {
  public init?(rawValue: Int) {
    if rawValue == 1 {
      self = .primary
    } else {
      self = .none
    }
  }

  public typealias RawValue = Int

  case primary = 1
  case none = 0
}
