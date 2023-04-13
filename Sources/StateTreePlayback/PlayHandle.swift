import Disposable
import Utilities

// MARK: - RecordHandle

public struct RecordHandle {
  public struct StopHandle {
    let autoDisposable: AutoDisposable
  }

  let stopFunc: () -> [StateFrame]
  public func stop() -> [StateFrame] { stopFunc() }
  public func autostop() -> StopHandle { .init(autoDisposable: AutoDisposable { _ = stop() }) }
}

// MARK: - RecordHandle.StopHandle + Disposable

extension RecordHandle.StopHandle: Disposable {
  public var isDisposed: Bool {
    autoDisposable.isDisposed
  }

  public func dispose() {
    autoDisposable.dispose()
  }
}
