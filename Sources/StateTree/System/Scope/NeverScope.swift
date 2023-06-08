import Behavior
import Disposable
import Emitter
import Foundation
import Intents
import OrderedCollections

// MARK: - NeverScope

struct NeverScope: ScopeTypeInternal {

  // MARK: Lifecycle

  nonisolated init() {
    assertionFailure("NeverScope should never be invoked")
    self._node = NeverNode()
  }

  // MARK: Internal

  typealias N = NeverNode

  struct NeverNode: Node {
    nonisolated init() {
      assertionFailure("NeverNode should never be invoked")
    }

    var rules: some Rules {
      assertionFailure("NeverScope should never be invoked")
      return .none
    }
  }

  struct NeverScopeError: Error { }

  var didUpdateEmitter: AnyEmitter<Void, Never> {
    Emitters.never.erase()
  }

  var nid: NodeID {
    assertionFailure("NeverScope should never be invoked")
    return .invalid
  }

  var depth: Int {
    assertionFailure("NeverScope should never be invoked")
    return Int.max
  }

  var node: N {
    assertionFailure("NeverScope should never be invoked")
    return _node
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

  var valueFieldDependencies: OrderedSet<FieldID> {
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

  func sendUpdateEvent() {
    assertionFailure("NeverScope should never be invoked")
  }

  func applyIntent(_: Intent) -> IntentStepResolution {
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

  func disconnectSendingNotification() {
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

  func stopSubtree() throws {
    assertionFailure("NeverScope should never be invoked")
  }

  func start() throws {
    assertionFailure("NeverScope should never be invoked")
  }

  func update() throws {
    assertionFailure("NeverScope should never be invoked")
  }

  func didUpdate() {
    assertionFailure("NeverScope should never be invoked")
  }

  func willStop() {
    assertionFailure("NeverScope should never be invoked")
  }

  func didStart() {
    assertionFailure("NeverScope should never be invoked")
  }

  func handleIntents() {
    assertionFailure("NeverScope should never be invoked")
  }

  func syncToStateReportingCreatedScopes() throws -> [AnyScope] {
    assertionFailure("NeverScope should never be invoked")
    throw NeverScopeError()
  }

  // MARK: Private

  private let _node: N
  private let uuid = UUID()

}
