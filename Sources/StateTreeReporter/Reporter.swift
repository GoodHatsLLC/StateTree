import Disposable
import Emitter
@_spi(Implementation) import StateTree

// MARK: - ObservableNode

@TreeActor
final class Reporter<N: Node> {

  // MARK: Lifecycle

  init(root: TreeLifetime<N>) {
    self.scope = root.root
    self.id = root.rootID
    self.disposable = start()
  }

  init(scope: NodeScope<N>) {
    self.scope = scope
    self.id = scope.id
    self.disposable = start()
  }

  // MARK: Internal

  let scope: NodeScope<N>

  func onChange(of _: NodeID, _ callback: @escaping @Sendable @TreeActor () -> Void) {
    onChangeSubscribers.append(callback)
  }

  func onStop(
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    onStopSubscribers.append(callback)
  }

  func onCancel(
    _ callback: @escaping @Sendable @TreeActor () -> Void
  ) {
    onCancelSubscribers.append(callback)
  }

  func start() -> AnyDisposable {
    scope
      .runtime
      .updateEmitter
      .subscribe { value in
        if Task.isCancelled {
          for sub in self.onCancelSubscribers {
            sub()
          }
          self.disposable?.dispose()
          return
        }
        switch value {
        case .stopped(let id) where self.id == id:
          for sub in self.onStopSubscribers {
            sub()
          }
          self.onStopSubscribers = []
          self.onChangeSubscribers = []
          self.disposable?.dispose()
        case .updated(let id) where self.id == id,
             .started(let id) where self.id == id:
          for sub in self.onChangeSubscribers {
            sub()
          }
        case _:
          break
        }
      }
  }

  // MARK: Private

  private let id: NodeID
  private var onChangeSubscribers: [@Sendable @TreeActor () -> Void] = []
  private var onStopSubscribers: [@Sendable @TreeActor () -> Void] = []
  private var onCancelSubscribers: [@Sendable @TreeActor () -> Void] = []
  private var disposable: AnyDisposable?
  private var runtime: Runtime?

}
