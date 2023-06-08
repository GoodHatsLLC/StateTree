import Foundation
import StateTree

public struct CountersList: Node {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  @Route public var counters: [Counter] = []

  public var rules: some Rules {
    Serve(data: counterIDs, at: $counters) { datum in
      Counter(
        id: datum,
        shouldDelete: {
          delete(counter: datum)
        }
      )
    }
  }

  public func addCounter() {
    $scope.transaction {
      let counter = nextCounter
      counterIDs.append(counter)
      nextCounter += 1
    }
  }

  public func delete(counter id: Int) {
    counterIDs.removeAll { $0 == id }
  }

  // MARK: Private

  @Value private var counterIDs: [Int] = []
  @Value private var nextCounter = 0
  @Scope private var scope

}
