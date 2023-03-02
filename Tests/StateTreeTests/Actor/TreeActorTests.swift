import Disposable
import StateTree
import XCTest

final class TreeActorTests: XCTestCase {

  func _test_printActor() throws {
    switch TreeActor.type {
    case .custom:
      Swift.print("🛠️ - @CustomActor aliased as @TreeActor")
    case .main:
      Swift.print("🎨 - @MainActor aliased as @TreeActor")
    }
  }

}
