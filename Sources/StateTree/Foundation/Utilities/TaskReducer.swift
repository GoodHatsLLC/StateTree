// MARK: - TaskReducer

@resultBuilder
public struct TaskReducer<Success: Sendable, Failure: Error> {
  public static func buildExpression(_ task: Task<Success, Failure>) -> [Task<Success, Failure>] {
    [task]
  }

  public static func buildBlock(_ tasks: [Task<Success, Failure>]...) -> [Task<Success, Failure>] {
    tasks.flatMap { $0 }
  }
}

extension Task where Failure == Error {

  public static func buildFinalResult(_ tasks: [Task<Success, Failure>])
    -> Task<[Success], Failure>
  {
    Task<[Success], Failure> {
      try await withThrowingTaskGroup(of: Success.self, returning: [Success].self) { taskGroup in
        for task in tasks {
          taskGroup.addTask {
            try await withTaskCancellationHandler {
              try await task.value
            } onCancel: {
              task.cancel()
            }
          }
        }
        return try await taskGroup.reduce(into: [Success]()) { partialResult, name in
          partialResult.append(name)
        }
      }
    }
  }
}

extension Task where Failure == Never {

  public static func buildFinalResult(_ tasks: [Task<Success, Failure>])
    -> Task<[Success], Failure>
  {
    Task<[Success], Failure> {
      await withTaskGroup(of: Success.self, returning: [Success].self) { taskGroup in
        for task in tasks {
          taskGroup.addTask {
            await withTaskCancellationHandler {
              await task.value
            } onCancel: {
              task.cancel()
            }
          }
        }
        return await taskGroup.reduce(into: [Success]()) { partialResult, name in
          partialResult.append(name)
        }
      }
    }
  }
}
