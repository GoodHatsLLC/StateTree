import StateTree
import ToDoDomain
import XCTest

final class ExclusiveAccessTests: XCTestCase {

  @MainActor
  func testExample() throws {
    let lifetime = try Tree.main
      .start(root: ToDoList())
    lifetime.rootNode.filteredToDos?[0].title = "test"
  }

}
