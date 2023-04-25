import Foundation
import StateTree

public struct Counter: Node, Identifiable {

  public let id: Int
  public let shouldDelete: () -> Void
  @Value public var count: Int = 0

  public var emoji: Emoji {
    Emoji.hash(of: id)
  }

  public var incrementDisabled: Bool {
    count == 10
  }

  public var decrementDisabled: Bool {
    count == -10
  }

  public var rules: some Rules {
    ()
    // We could also enforce the count with a rule set.
    //
    // if count > 10 {
    //   count = 10
    // } else if count < -10 {
    //   count = -10
    // }
  }

  public func increment() {
    if count < 10 {
      count += 1
    }
  }

  public func decrement() {
    if count > -10 {
      count -= 1
    }
  }

  public func delete() {
    shouldDelete()
  }

}
