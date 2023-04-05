import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTree
import SwiftUI
import Utilities

// MARK: - ReportedTree

@TreeActor
public final class ReportedTree<N: Node> {

  // MARK: Lifecycle

  public init(tree: Tree = .main, root: N) {
    self.reportedFunc = {
      let life = try tree.start(root: root)
      return (.init(projectedValue: .init(tree: life)), life)
    }
  }

  // MARK: Public

  public var root: Reported<N> {
    get async throws {
      let values = subject.compactMap { $0 }.values
      for try await value in values {
        return value
      }
      throw TreeLifetimeCancelledError()
    }
  }

  public func start() async throws {
    guard lifetime == nil
    else {
      throw TreeAlreadyStartedError()
    }
    let (reported, lifetime) = try reportedFunc()
    self.lifetime = lifetime
    subject.emit(value: reported)
    let asyncValue = Async.ThrowingValue<Void>()
    reported.onStop(subscriber: self) {
      Task { await asyncValue.resolve(()) }
    }
    return try await withTaskCancellationHandler {
      try await asyncValue.value
    } onCancel: {
      lifetime.dispose()
    }
  }

  // MARK: Private

  private var lifetime: TreeLifetime<N>?
  private let subject = ValueSubject<Reported<N>?>(nil)
  private let reportedFunc: () throws -> (Reported<N>, TreeLifetime<N>)

}

// MARK: - TreeAlreadyStartedError

public struct TreeAlreadyStartedError: Error { }

// MARK: - TreeLifetimeCancelledError

public struct TreeLifetimeCancelledError: Error { }
