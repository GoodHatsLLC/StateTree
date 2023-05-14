import Disposable
import Utilities

public final class TestTreeManager {

  // MARK: Lifecycle

  public init() { }

  deinit {
    tearDown()
  }

  // MARK: Public

  public func tearDown() {
    let lifetimes = lifetimes.withLock { lifetimes in
      let finishedLifetimes = lifetimes
      lifetimes = []
      return finishedLifetimes
    }
    for lifetime in lifetimes {
      lifetime.dispose()
    }
  }

  // MARK: Internal

  func own(lifetime: AutoDisposable) {
    lifetimes.withLock { lifetimes in
      lifetimes.append(lifetime)
    }
  }

  // MARK: Private

  private let lifetimes = Locked<[AutoDisposable]>([])
}
