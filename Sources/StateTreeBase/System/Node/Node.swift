import Disposable
import TreeActor

// MARK: - Node

@TreeActor
public protocol Node {
  associatedtype NodeRules: Rules
  @RuleBuilder var rules: Self.NodeRules { get }
}
