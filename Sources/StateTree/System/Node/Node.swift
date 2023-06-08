import Disposable
import TreeActor

// MARK: - Node

@TreeActor
public protocol Node {
  associatedtype NodeRules: Rules
  @RuleBuilder var rules: Self.NodeRules { get }
}

extension Node {
  internal var identity: LSID? {
    if let self = self as? (any Node & Identifiable) {
      return LSID.from(self)
    } else {
      return nil
    }
  }
}
