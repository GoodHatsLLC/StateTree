// MARK: - IntentStepResolution

public enum IntentStepResolution {
  case inapplicable
  case pending
  case application(() -> Void)

  public var isApplicable: Bool {
    switch self {
    case .application,
         .pending: return true
    case .inapplicable: return false
    }
  }
}

// MARK: - IntentAction

public enum IntentAction {
  case pend
  case act(() -> Void)
}

extension IntentAction {
  public init(_ action: (() -> Void)?) {
    if let action {
      self = .act(action)
    } else {
      self = .pend
    }
  }
}

extension IntentStepResolution {
  public init(_ resolution: IntentAction) {
    switch resolution {
    case .pend:
      self = .pending
    case .act(let act):
      self = .application(act)
    }
  }

}
