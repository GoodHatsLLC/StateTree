import Foundation
import StateTree

public struct CountersList: Node {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  @Route([Counter].self) public var counters

  public var rules: some Rules {
    $counters.route {
      counterIDs
        .map { id in
          Counter(
            id: id,
            shouldDelete: {
              delete(counter: id)
            }
          )
        }
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
