// MARK: - StepResolutionInternal

@_spi(Implementation)
public enum StepResolutionInternal {
  case inapplicable
  case pending
  case application(@TreeActor () -> Void)

  var isApplicable: Bool {
    switch self {
    case .application,
         .pending: return true
    case .inapplicable: return false
    }
  }
}

// MARK: - IntentStepResolution

public enum IntentStepResolution {
  case pending
  case resolution(@TreeActor () -> Void)
}

extension StepResolutionInternal {
  init(_ resolution: IntentStepResolution) {
    switch resolution {
    case .pending:
      self = .pending
    case .resolution(let act):
      self = .application(act)
    }
  }

}
