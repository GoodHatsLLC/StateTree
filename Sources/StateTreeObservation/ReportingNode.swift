import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTree

// MARK: - ObservableNode

@TreeActor
public final class Reporter<T: Node> {

  // MARK: Lifecycle

  init(lifetime: TreeLifetime<T>) {
    self.lifetime = lifetime
    self.disposable = start()
  }

  // MARK: Public

  public func onChange(of node: NodeID, _ callback: @escaping @Sendable @TreeActor () -> Void) {
    subscribers[node, default: []].append(callback)
  }

  // MARK: Internal

  func start() -> AnyDisposable {
    lifetime
      .updateEmitter
      .flatMapLatest { id in self.subscribersEmitter(for: id) }
      .subscribe { subscribers in
        subscribers.forEach {
          $0()
        }
      }
    // TODO: add node-stop emitter for cleanup
  }

  // MARK: Private

  private let lifetime: TreeLifetime<T>
  private var subscribers: [NodeID: [@Sendable @TreeActor () -> Void]] = [:]
  private var disposable: AnyDisposable?

  private nonisolated func subscribersEmitter(for nodeID: NodeID) -> some Emitter <
    [@Sendable @TreeActor () -> Void]> {
      Emitters.create([@Sendable @TreeActor () -> Void].self) { emit in
        if let subs = await self.subscribers[nodeID] {
          emit(.value(subs))
        }
        emit(.finished)
      }
    }

}
