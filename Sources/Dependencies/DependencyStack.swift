// MARK: - DependencyStack

@MainActor
public enum DependencyStack {

  public static var top: DependencyValues {
    get throws {
      guard let top = stack.last
      else {
        throw NoDependencyStackValue()
      }
      return top
    }
  }

  public static var topOrDefault: DependencyValues {
    stack.last ?? .defaults
  }

  public static func push<T>(_ dependencies: DependencyValues, for lifetime: () throws -> T)
    rethrows -> T
  {
    stack.append(dependencies)
    defer { stack.removeLast() }
    return try lifetime()
  }

  private static var stack: [DependencyValues] = []

}

// MARK: - NoDependencyStackValue

struct NoDependencyStackValue: Error {}
