import Disposable
import Emitter
import Foundation
@_spi(Implementation) import StateTree
import SwiftUI

// MARK: - ReportedRoot

@TreeActor
public final class ReportedRoot<N: Node> {

  // MARK: Lifecycle

  init(tree: Tree = .main, root: N) {
    self.reportedFunc = {
      let life = try tree.start(root: root)
      return .init(projectedValue: .init(tree: life))
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
    guard reported == nil
    else {
      throw TreeAlreadyStartedError()
    }
    let reported = try reportedFunc()
    subject.emit(.value(reported))
    self.reported = reported
    let asyncValue = AsyncThrowingValue<Void>()
    let disposable = reported
      .projectedValue
      .start()
    reported
      .projectedValue
      .onStop {
        asyncValue.resolve(())
        disposable.dispose()
      }
    reported
      .onCancel {
        asyncValue.fail(TreeLifetimeCancelledError())
        disposable.dispose()
      }
    reported
      .onChange {
        for change in self.onChangeSubscribers {
          change()
        }
      }
    return try await asyncValue.value
  }

  // MARK: Private

  private let subject = ValueSubject<Reported<N>?>(nil)
  private var reported: Reported<N>?
  private let reportedFunc: () throws -> Reported<N>

  private var onChangeSubscribers: [@Sendable @TreeActor () -> Void] = []

}

// MARK: - TreeAlreadyStartedError

public struct TreeAlreadyStartedError: Error { }

// MARK: - TreeLifetimeCancelledError

public struct TreeLifetimeCancelledError: Error { }
