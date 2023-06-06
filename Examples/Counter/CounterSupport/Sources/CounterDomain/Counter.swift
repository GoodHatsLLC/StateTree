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
    OnUpdate(count) { _ in
      count = max(min(10, count), -10)
    }
  }

  public func increment() {
    count += 1
  }

  public func decrement() {
    count -= 1
  }

  public func delete() {
    shouldDelete()
  }

}
