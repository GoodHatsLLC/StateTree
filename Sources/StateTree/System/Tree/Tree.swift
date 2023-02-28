import Disposable
import Emitter
import Foundation

// MARK: - Tree

@TreeActor
public final class Tree {

  // MARK: Lifecycle

  public nonisolated init() { }

  // MARK: Public

  public nonisolated static let main: Tree = .init()

  @_spi(Implementation) public var runtime: Runtime? {
    _runtime
  }

  public var _info: StateTreeInfo? { _runtime?._info }

  // MARK: Private

  private var _runtime: Runtime?

}

extension Tree {

  // MARK: Public

  /// TODO: If lifetime is collapsed into Tree this start() can become async throws.
  /// This would allow for a configuration that throws an exception if a circular
  /// dependency is hit — and allows the consumer to restart the tree with the last
  /// state if so desired.
  @TreeActor
  public func start<N: Node>(
    root: N,
    from initialState: TreeStateRecord? = nil,
    dependencies: DependencyValues = .defaults,
    configuration: RuntimeConfiguration = .init()
  ) throws -> TreeLifetime<N> {
    let runtime = Runtime(
      tree: self,
      dependencies: dependencies,
      configuration: configuration
    )

    try setRuntime(runtime)

    let scope = try runtime.start(
      rootNode: root,
      initialState: initialState
    )

    assert(runtime.isConsistent)
    let disposable = AnyDisposable {
      try? self.setRuntime(nil)
      assert(runtime.isConsistent)
      runtime.stop()
      assert(runtime.isConsistent)
    }
    let lifetime = TreeLifetime(
      runtime: runtime,
      root: scope,
      rootID: scope.id,
      disposable: disposable
    )
    return lifetime
  }

  // MARK: Internal

  func setRuntime(_ runtime: Runtime?) throws {
    if runtime != nil, _runtime != nil {
      throw StartedTreeError()
    }
    _runtime = runtime
  }

}
