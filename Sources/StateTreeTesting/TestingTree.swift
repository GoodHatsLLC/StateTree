@_spi(Implementation) import StateTree
@_spi(Implementation) import Disposable
import StateTreePlayback
import Utilities

// MARK: - TestingTree

@propertyWrapper
public struct TestingTree<NodeType: Node> {

  // MARK: Lifecycle

  public nonisolated init(
    moduleFile: String = #file,
    line: UInt = #line,
    allowUnmanagedAccess: Bool = false,
    wrappedValue: NodeType
  ) {
    self.initialNode = wrappedValue
    self.moduleFile = moduleFile
    self.line = line
    self.allowUnmanagedAccess = allowUnmanagedAccess
  }

  // MARK: Public

  public struct IllegalTestingTreeReuseError: Error, CustomStringConvertible {
    public let description: String
  }

  public struct UnstartedTreeError: Error, CustomStringConvertible {
    public let description: String = "The StateTree was unstarted"
  }

  public nonisolated var dependencies: DependencyValues {
    get {
      state.value.dependencies
    }
    nonmutating set {
      state.withLock { state in
        if state.startRecord != nil {
          preconditionFailure("The StateTree is already started and dependencies can't be set.")
        }
        state.dependencies = newValue
      }
    }
  }

  public nonisolated var interceptors: [BehaviorInterceptor] {
    get {
      state.value.interceptors
    }
    nonmutating set {
      state.withLock { state in
        if state.startRecord != nil {
          preconditionFailure("The StateTree is already started and interceptors can't be set.")
        }
        state.interceptors = newValue
      }
    }
  }

  public var wrappedValue: NodeType {
    get {
      guard let startRecord = try? getStartRecord()
      else {
        if allowUnmanagedAccess {
          return initialNode
        } else {
          preconditionFailure(
            """
            The Tree has not been started.
            The root node is unmanaged.

            You can enable unmanaged testing by instantiating the TestingTree as follows:
            ```
            let tree = TestingTree(allowUnmanagedAccess: true, wrappedValue: <\(
              NodeType
                .self
            ).init(...)>)
            ```
            """
          )
        }
      }
      if !startRecord.tree.isActive, !allowUnmanagedAccess {
        preconditionFailure(
          """
          The Tree has stopped.
          The root node is unmanaged.

          You can enable unmanaged testing by instantiating the TestingTree as follows:
          ```
          let tree = TestingTree(allowUnmanagedAccess: true, wrappedValue: <\(
            NodeType
              .self
          ).init(...)>)
          ```
          """
        )
      }
      return startRecord.lifetime.root.node
    }
    nonmutating set { }
  }

  public var projectedValue: TestingTree<NodeType> {
    get { self }
    nonmutating set { }
  }

  @TreeActor
  public func start(
    with manager: TestTreeManager,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) throws {
    try state.withLock { state in
      if let startRecord = state.startRecord {
        throw IllegalTestingTreeReuseError(
          description:
          """
          TestingTree can not be started multiple times.
          (Initially started at: \(startRecord.file):\(startRecord.line))
          """
        )
      }
      let tree = Tree(
        root: initialNode,
        dependencies: state.dependencies,
        interceptors: state.interceptors
      )
      let lifetime = try tree.start(from: state.startState)
      state.startRecord = StartRecord(
        lifetime: lifetime,
        tree: tree,
        manager: manager,
        file: file,
        line: line
      )
    }
  }

  @discardableResult
  @TreeActor
  public func stop() throws -> Result<TreeStateRecord, TreeError> {
    let record = try getStartRecord()
    return try record.lifetime.stop()
  }

  public func awaitBehaviors(timeoutSeconds: Double? = nil) async throws {
    let record = try getStartRecord()
    try await record.tree.behaviorTracker.awaitBehaviors(timeoutSeconds: timeoutSeconds)
  }

  @discardableResult
  public func awaitFinished(timeoutSeconds: Double? = nil) async throws
    -> Result<TreeStateRecord, TreeError>
  {
    let record = try getStartRecord()
    let result = await Async.timeout(seconds: timeoutSeconds) {
      await record.lifetime.onFinish()
    }
    return try result.get()
  }

  @TreeActor
  public func flushUpdateStats() throws -> UpdateStats {
    let record = try getStartRecord()
    return try record.tree.assume.info.flushUpdateStats()
  }

  // MARK: Private

  private struct State {
    var dependencies: DependencyValues = .defaults
    var interceptors: [BehaviorInterceptor] = []
    var startState: TreeStateRecord?
    var startRecord: StartRecord?
  }

  private struct StartRecord {
    let lifetime: TreeHandle<NodeType>
    let tree: Tree<NodeType>
    let manager: TestTreeManager
    let file: StaticString
    let line: UInt
  }

  private var state: Locked<State> = .init(.init())
  private let initialNode: NodeType
  private let moduleFile: String
  private let line: UInt
  private let allowUnmanagedAccess: Bool

  private func getStartRecord() throws -> StartRecord {
    guard let record = state.value.startRecord
    else {
      throw UnstartedTreeError()
    }
    return record
  }

}
