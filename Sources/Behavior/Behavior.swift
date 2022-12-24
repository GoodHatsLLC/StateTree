import BehaviorInterface
import SourceLocation

/// A `Behavior` is a wrapper around arbitrary work like a Swift `Task`.
/// The wrapper allows the work to be run bound to an owning `BehaviorHost` and to be mocked for testing.
@MainActor
public struct Behavior<Output>: BehaviorType {

  public init(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: String? = nil,
    action: @escaping () async throws -> Output
  ) {
    self.id = id ?? "unknown"
    self.action = action
    _initLocation = SourceLocation(
      fileID: fileID,
      line: line,
      column: column
    )
  }

  public let id: String
  public let action: () async throws -> Output
  public let _initLocation: SourceLocation

  public func produce<Host: _BehaviorHost>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    with host: Host
  ) async throws
    -> Output
  {
    try await host
      ._produce(
        self,
        from: SourceLocation(
          fileID: fileID,
          line: line,
          column: column
        )
      )()
  }

  public func produce<Host: _BehaviorHost>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    with host: Host,
    handler: @escaping @MainActor (Result<Output, Error>) -> Void
  ) {
    Task {
      do {
        let value =
          try await host
          ._produce(
            self,
            from: SourceLocation(
              fileID: fileID,
              line: line,
              column: column
            )
          )()
        handler(.success(value))
      } catch {
        handler(.failure(error))
      }
    }
  }

  public func run<Host: _BehaviorHost>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    with host: Host
  ) {
    host
      ._run(
        self,
        from: SourceLocation(
          fileID: fileID,
          line: line,
          column: column
        )
      )
  }

}
