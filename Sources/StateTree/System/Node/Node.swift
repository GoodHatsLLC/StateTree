import Disposable

// MARK: - Node

@TreeActor
public protocol Node {
  associatedtype NodeRules: Rules
  @RuleBuilder var rules: Self.NodeRules { get }
}

extension Node {
  nonisolated var uniqueIdentity: String? {
    guard let identifiableNode = self as? any Identifiable
    else {
      return nil
    }
    let id = identifiableNode.id
    let hashID = AnyHashable(id)
    return hashID.description
  }
}
