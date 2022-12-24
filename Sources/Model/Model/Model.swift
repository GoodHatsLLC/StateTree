import BehaviorInterface
import Dependencies
import Disposable
import Emitter
import Foundation
import ModelInterface
import Node
import Projection
import SourceLocation
import TreeInterface
import Utilities

// MARK: - Model

@MainActor
public protocol Model<State>: _BehaviorHost, Equatable, CustomStringConvertible {
  /// The domain model's state.
  ///
  /// This should be directly defined and conformed to `StateType` by
  /// being `Codable`, `Sendable` and `Equatable`.
  ///
  /// ```swift
  ///     struct State: StateType {
  ///         // Codable, Sendable, Equatable
  ///         let propertyOne: Bool
  ///         let propertyTwo: MyValueType
  ///     }
  /// ```
  associatedtype State: ModelState

  associatedtype Routes: Routing

  nonisolated var store: Store<Self> { get }

  @RouteBuilder
  func route(state: Projection<State>) -> Self.Routes

}

// MARK: Equatable
extension Model {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.store._storage.state == rhs.store._storage.state
  }
}

extension Model {
  public var submodels: [any Model] {
    store.submodels
  }
}

extension Model {
  public var description: String {
    "\(Self.self)"
  }

  public var debugDescription: String {
    debugDump()
  }

  public func debugDump() -> String {
    var out = String()
    dump(store._storage.state, to: &out, name: "\(Self.self)")
    return out
  }
}

// MARK: - RootStartConfig

public struct RootStartConfig {

  public static let defaults = RootStartConfig(
    hooks: .noop, startMode: .interactive, dependencies: .defaults
  )

  public init(
    hooks: StateTreeHooks,
    startMode: StartMode,
    dependencies: DependencyValues
  ) {
    self.hooks = hooks
    self.startMode = startMode
    self.dependencies = dependencies
  }

  let hooks: StateTreeHooks
  let startMode: StartMode
  let dependencies: DependencyValues
}

extension Model {

  public var projection: Projection<Self> {
    Projection(
      upstream: Access.CapturedAccess<Self>(
        getter: { self },
        setter: { _ in },
        isValid: { store._storage.isValid() }
      ),
      map: Transform.Passthrough()
    )
  }

  public static func _startedAsRoot(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    config: RootStartConfig = .defaults,
    stage: DisposalStage,
    _ builder: () -> Self
  ) throws -> Self {
    let receiver = ModelAnnotationSink<Self>()
    let model = ModelAnnotationCollector.endpoint
      .using(receiver: receiver) {
        builder()
      }
    try model._startAsRoot(
      sourceIdentity: .root(
        .init(
          fileID: fileID,
          line: line,
          column: column
        )
      ),
      config: config,
      annotations: receiver.annotations
    )
    .stage(on: stage)
    return model
  }

  @available(*, deprecated)
  @MainActor
  public func _startAsRoot(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    sourceIdentity: SourcePath? = nil,
    config: RootStartConfig,
    annotations: [ModelAnnotation<Self>]
  ) throws
    -> AnyDisposable
  {
    let metaRoot = RootNode()
    let meta = StoreMeta(
      hooks: config.hooks,
      routeIdentity: sourceIdentity ?? .root(.init(fileID: fileID, line: line, column: column)),
      startMode: config.startMode,
      dependencies: config.dependencies,
      upstream: metaRoot
    )
    return try store._storage.start(
      model: self,
      meta: meta,
      annotations: annotations
    )
  }

}

extension Model {
  func route(state _: Projection<State>) -> VoidRoute {
    VoidRoute()
  }

  func accumulateState(with accumulator: StateAccumulator) throws {
    try store._storage.accumulateState(with: accumulator)
  }

}

extension Model {

  public func _produce<B: BehaviorType>(
    _ behavior: B,
    from location: SourceLocation
  )
    -> (() async throws -> B.Output)
  {
    store.produce(behavior, from: location)
  }

  public func _run<B: BehaviorType>(
    _ behavior: B,
    from location: SourceLocation
  ) {
    store.run(behavior, from: location)
  }

}

extension Model where State: Identifiable {

  public typealias ID = State.ID

  public var id: State.ID {
    store.read.id
  }

}

extension Model {
  public func dumpTree(fn: (any Model) -> String) -> String {
    var collector = [(String, String)]()
    dumpLevel(level: 0, fn: fn, out: &collector)
    let header = ("Depth", "fn -> _")
    let leftLen =
      (collector + [header]).map(\.0)
      .max(by: { $0.count < $1.count })?.count ?? 0
    let rightLen =
      (collector + [header]).map(\.1)
      .max(by: { $0.count < $1.count })?.count ?? 0
    let template: (String, String) -> String = {
      "| \($0 + String(repeating: " ", count: leftLen - $0.count)) | \($1 + String(repeating: " ", count: rightLen - $1.count)) |"
    }
    return
      ([
        template(header.0, header.1),
        template(String(repeating: "-", count: leftLen), String(repeating: "-", count: rightLen)),
      ]
      + collector.map { template($0.0, $0.1) })
      .joined(separator: "\n")
  }

  private func dumpLevel(level: Int, fn: (any Model) -> String, out: inout [(String, String)]) {
    out
      .append(
        (
          "\(level)",
          String(repeating: " ", count: level)
            + fn(self).replacingOccurrences(of: "\n", with: " ⏎ ")
        )
      )
    for model in submodels {
      model.dumpLevel(level: level + 1, fn: fn, out: &out)
    }
  }
}
