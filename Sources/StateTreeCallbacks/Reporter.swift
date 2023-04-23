import Disposable
import Emitter
@_spi(Implementation) import StateTree

// MARK: - ObservableNode

@TreeActor
final class Reporter<N: Node> {

  // MARK: Lifecycle

  init(scope: NodeScope<N>) {
    self.scope = scope
    self.id = scope.nid
    self.disposable = start()
  }

  // MARK: Internal

  let scope: NodeScope<N>

  func onChange(
    owner: ObjectIdentifier,
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    onChangeSubscribers[owner, default: []].append(callback)
  }

  func onStop(
    owner: ObjectIdentifier,
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    onStopSubscribers[owner, default: []].append(callback)
  }

  func unregister(subscriber: ObjectIdentifier) {
    onChangeSubscribers.removeValue(forKey: subscriber)
    onStopSubscribers.removeValue(forKey: subscriber)
  }

  func start() -> AutoDisposable {
    scope
      .runtime
      .updateEmitter
      .compactMap(\.maybeNode)
      .subscribe { value in
        if Task.isCancelled {
          for sub in self.onStopSubscribers.values.flatMap({ $0 }) {
            sub()
          }
          self.disposable?.dispose()
          return
        }
        switch value {
        case .stop(let id, _) where self.id == id:
          for sub in self.onStopSubscribers.values.flatMap({ $0 }) {
            sub()
          }
          self.onStopSubscribers = [:]
          self.onChangeSubscribers = [:]
          self.disposable?.dispose()
        case .update(let id, _) where self.id == id,
             .start(let id, _) where self.id == id:
          for sub in self.onChangeSubscribers.values.flatMap({ $0 }) {
            sub()
          }
        case _:
          break
        }
      }
  }

  // MARK: Private

  private let id: NodeID
  private var onChangeSubscribers: [ObjectIdentifier: [@Sendable @TreeActor () -> Void]] = [:]
  private var onStopSubscribers: [ObjectIdentifier: [@Sendable @TreeActor () -> Void]] = [:]
  private var disposable: AutoDisposable?
  private var runtime: Runtime?

}
