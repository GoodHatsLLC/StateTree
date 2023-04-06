import Behavior
import Disposable
import Foundation
// MARK: - NeverScope

struct NeverScope: ScopeType {

  // MARK: Lifecycle

  nonisolated init() {
    assertionFailure("NeverScope should never be invoked")
    self._node = NeverNode()
  }

  // MARK: Internal

  struct NeverNode: Node {
    nonisolated init() {
      assertionFailure("NeverNode should never be invoked")
    }

    var rules: some Rules {
      assertionFailure("NeverScope should never be invoked")
      return .none
    }
  }

  typealias N = NeverNode
  struct NeverScopeError: Error { }

  var nid: NodeID {
    assertionFailure("NeverScope should never be invoked")
    return .invalid
  }

  var depth: Int {
    assertionFailure("NeverScope should never be invoked")
    return Int.max
  }

  var cuid: CUID? {
    assertionFailure("NeverScope should never be invoked")
    return .invalid
  }

  var node: N {
    get {
      assertionFailure("NeverScope should never be invoked")
      return _node
    }
    nonmutating set { }
  }

  var isActive: Bool {
    assertionFailure("NeverScope should never be invoked")
    return false
  }

  var childScopes: [AnyScope] {
    assertionFailure("NeverScope should never be invoked")
    return []
  }

  var initialCapture: NodeCapture {
    assertionFailure("NeverScope should never be invoked")
    return .init(_node)
  }

  var record: NodeRecord {
    get {
      assertionFailure("NeverScope should never be invoked")
      return .init(id: .invalid, origin: .invalid, records: [])
    }
    nonmutating set {
      assertionFailure("NeverScope should never be invoked")
    }
  }

  var dependencies: DependencyValues {
    assertionFailure("NeverScope should never be invoked")
    return .defaults
  }

  var valueFieldDependencies: Set<FieldID> {
    assertionFailure("NeverScope should never be invoked")
    return []
  }

  var requiresReadying: Bool {
    assertionFailure("NeverScope should never be invoked")
    return false
  }

  var isStable: Bool {
    assertionFailure("NeverScope should never be invoked")
    return true
  }

  var requiresFinishing: Bool {
    assertionFailure("NeverScope should never be invoked")
    return true
  }

  static func == (_: NeverScope, _: NeverScope) -> Bool {
    assertionFailure("NeverScope should never be invoked")
    return false
  }

  func applyIntent(_: Intent) -> StepResolutionInternal {
    assertionFailure("NeverScope should never be invoked")
    return .inapplicable
  }

  func hash(into _: inout Hasher) {
    assertionFailure("NeverScope should never be invoked")
  }

  func own(_ disposable: some Disposable) {
    assertionFailure("NeverScope should never be invoked")
    disposable.dispose()
  }

  func canOwn() -> Bool {
    assertionFailure("NeverScope should never be invoked")
    return false
  }

  func stepTowardsFinished() throws -> Bool {
    assertionFailure("NeverScope should never be invoked")
    throw NeverScopeError()
  }

  func stop() throws {
    assertionFailure("NeverScope should never be invoked")
  }

  func markDirty(pending _: ExternalRequirement) {
    assertionFailure("NeverScope should never be invoked")
  }

  func stepTowardsReady() throws -> Bool {
    assertionFailure("NeverScope should never be invoked")
    throw NeverScopeError()
  }

  func erase() -> AnyScope {
    assertionFailure("NeverScope should never be invoked")
    return AnyScope(scope: self)
  }

  // MARK: Private

  private let _node: N
  private let uuid = UUID()

}
