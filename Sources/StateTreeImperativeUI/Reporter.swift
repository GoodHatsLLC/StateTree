import Disposable
import Emitter
@_spi(Implementation) import StateTreeBase
import TreeActor

// MARK: - Reporter + ScopeAccess

extension Reporter: ScopeAccess { }

// MARK: - Reporter

@TreeActor
public final class Reporter<N: Node>: RouterAccess, NodeAccess {

  // MARK: Lifecycle

  init(scope: NodeScope<N>) {
    self.scope = scope
    self.id = scope.nid
    self.disposable = start()
  }

  // MARK: Public

  public typealias Accessor = Reporter<N>

  public typealias NodeType = N

  @_spi(Implementation) public let scope: NodeScope<N>

  @_spi(Implementation) public var access: Reporter<N> { self }

  public func onChange(
    subscriber: some Hashable,
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
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

  private func start() -> AutoDisposable {
    scope
      .didUpdateEmitter
      .subscribe {
        if Task.isCancelled {
          for sub in self.onStopSubscribers.values.flatMap({ $0 }) {
            sub()
          }
          self.disposable?.dispose()
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
      }
  }

}
