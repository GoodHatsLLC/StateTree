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

  public init(tree: Tree<N>) {
    self.tree = tree
  }

  private let tree: Tree<N>

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
    let rep = try await withThrowingTaskGroup(of: Reported<N>.self) { group in
      group.addTask {
        let tree = self.tree
        _ = try await tree.run().get()
        return await Reported(tree: tree)
      }
      group.addTask {
        let tree = self.tree
        await tree.awaitRunning()
        return await Reported(tree: tree)
      }
      return try await group.first { _ in true }
    }
    subject.emit(value: rep)
  }

  // MARK: Private

  private let subject = ValueSubject<Reported<N>?>(nil)

}

// MARK: - TreeAlreadyStartedError

public struct TreeAlreadyStartedError: Error { }

// MARK: - TreeLifetimeCancelledError

public struct TreeLifetimeCancelledError: Error { }
