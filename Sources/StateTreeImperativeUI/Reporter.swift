import Disposable
import Emitter
@_spi(Implementation) import StateTree
import TreeActor
import Utilities

// MARK: - Reporter + ScopeAccess

extension Reporter: ScopeAccess { }

// MARK: - Reporter

@propertyWrapper
@TreeActor
public final class Reporter<NodeType: Node>: RouterAccess {

  // MARK: Lifecycle

  init(scope: NodeScope<NodeType>) {
    self.scope = scope
    self.id = scope.nid
  }

  // MARK: Public

  public typealias Accessor = Reporter<NodeType>

  @_spi(Implementation) public let scope: NodeScope<NodeType>

  @_spi(Implementation) public var access: Reporter<NodeType> { self }

  public var wrappedValue: NodeType {
    get { scope.node }
    set {
      runtimeWarning(
        "attempting to write to unmanaged node components. this won't be reflected. %@",
        [String(describing: scope.node)]
      )
    }
  }

  public var projectedValue: Reporter<NodeType> {
    self
  }

  public func onChange(
    subscriber: some Hashable,
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    startIfNeeded()
    onChangeSubscribers[AnyHashable(subscriber), default: []].append(callback)
  }

  public func onChange(
    subscriber: AnyObject,
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    onChange(subscriber: ObjectIdentifier(subscriber), callback)
  }

  public func onStop(
    subscriber: some Hashable,
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    startIfNeeded()
    onStopSubscribers[AnyHashable(subscriber), default: []].append(callback)
  }

  public func onStop(
    subscriber: AnyObject,
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    onStop(subscriber: ObjectIdentifier(subscriber), callback)
  }

  public func unregister(subscriber: some Hashable) {
    onChangeSubscribers.removeValue(forKey: subscriber)
    onStopSubscribers.removeValue(forKey: subscriber)
  }

  public func unregister(subscriber: AnyObject) {
    unregister(subscriber: ObjectIdentifier(subscriber))
  }

  // MARK: Private

  private let id: NodeID
  private var onChangeSubscribers: [AnyHashable: [@Sendable @TreeActor () -> Void]] = [:]
  private var onStopSubscribers: [AnyHashable: [@Sendable @TreeActor () -> Void]] = [:]
  private var disposable: AutoDisposable?
  private var runtime: Runtime?

  private func startIfNeeded() {
    disposable = disposable ?? start()
  }

  private func start() -> AutoDisposable {
    scope
      .didUpdateEmitter
      .subscribe {
        if Task.isCancelled {
          for sub in self.onStopSubscribers.values.flatMap({ $0 }) {
            sub()
          }
          self.disposable?.dispose()
          self.disposable = nil
          return
        }
        for sub in self.onChangeSubscribers.values.flatMap({ $0 }) {
          sub()
        }
      } finished: {
        for sub in self.onStopSubscribers.values.flatMap({ $0 }) {
          sub()
        }
        self.onStopSubscribers = [:]
        self.onChangeSubscribers = [:]
        self.disposable?.dispose()
        self.disposable = nil
      }
  }

}
