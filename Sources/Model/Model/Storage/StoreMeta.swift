import Dependencies
import Node
import SourceLocation
import TreeInterface
import Utilities

// MARK: - StoreMeta

public struct StoreMeta: CopyEdit {
  public init(
    hooks: StateTreeHooks,
    routeIdentity: SourcePath,
    startMode: StartMode,
    dependencies: DependencyValues,
    upstream: any StateNode
  ) {
    self.hooks = hooks
    self.routeIdentity = routeIdentity
    self.startMode = startMode
    self.dependencies = dependencies
    self.upstream = upstream
  }

  var hooks: any StateTreeHooks
  var routeIdentity: SourcePath
  var startMode: StartMode
  var dependencies: DependencyValues
  var upstream: any StateNode
}

// MARK: - CopyEdit

public protocol CopyEdit {}

extension CopyEdit {
  public func copyEdit(editor: (_ copy: inout Self) -> Void) -> Self {
    var copy = self
    editor(&copy)
    return copy
  }
}
