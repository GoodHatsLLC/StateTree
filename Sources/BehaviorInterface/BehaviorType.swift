import SourceLocation

// MARK: - BehaviorType

@MainActor
public protocol BehaviorType {
  associatedtype Output

  var id: String { get }
  var action: () async throws -> Output { get }
  var _initLocation: SourceLocation { get }
  func produce<Host: _BehaviorHost>(
    fileID: String,
    line: Int,
    column: Int,
    with host: Host
  ) async throws -> Output

  func run<Host: _BehaviorHost>(
    fileID: String,
    line: Int,
    column: Int,
    with host: Host
  )
}
