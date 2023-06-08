import Disposable
import Utilities

// MARK: - PlayHandle

public struct PlayHandle {
  public struct StopHandle {
    let autoDisposable: AutoDisposable
  }

  let stopFunc: () -> [StateFrame]
  public func stop() -> [StateFrame] { stopFunc() }
  public func autostop() -> StopHandle { .init(autoDisposable: AutoDisposable { _ = stop() }) }
}

// MARK: - PlayHandle.StopHandle + Disposable

extension PlayHandle.StopHandle: Disposable {
  public var isDisposed: Bool {
    autoDisposable.isDisposed
  }

  public func dispose() {
    autoDisposable.dispose()
  }
}
