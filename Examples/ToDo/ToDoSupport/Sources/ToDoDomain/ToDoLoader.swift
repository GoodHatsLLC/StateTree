import Foundation
import StateTree

struct ToDoLoader: Node {

  @Projection var toDoData: [UUID: ToDoData]

  var rules: some Rules {
    OnStart {
      toDoData = Array(
        repeating: (),
        count: 1000
      ).map {
        ToDoData(
          id: UUID(),
          tagIDs: [],
          isCompleted: false,
          creationDate: .now,
          title: "HELLO"
        )
      }.indexed(by: \.id)
    }
  }
}
