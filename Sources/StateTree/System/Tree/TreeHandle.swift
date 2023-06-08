import Disposable
import Utilities

// MARK: - TreeHandle

public struct TreeHandle<NodeType: Node> {
  public struct StopHandle {
    let autoDisposable: AutoDisposable
  }

  public var node: NodeType {
    root.node
  }

  let asyncValue: Async.Value<Result<TreeStateRecord, TreeError>>
  let stopFunc: () throws -> Result<TreeStateRecord, TreeError>
  public func onFinish() async -> Result<TreeStateRecord, TreeError> {
    await asyncValue.value
  }

  public func stop() throws -> Result<TreeStateRecord, TreeError> { try stopFunc() }
  public func autostop() -> StopHandle { .init(autoDisposable: AutoDisposable { _ = try? stop() }) }
  @_spi(Implementation) public let root: NodeScope<NodeType>
}

// MARK: - TreeHandle.StopHandle + Disposable

extension TreeHandle.StopHandle: Disposable {
  public var isDisposed: Bool {
    autoDisposable.isDisposed
  }

  public func dispose() {
    autoDisposable.dispose()
  }
}
