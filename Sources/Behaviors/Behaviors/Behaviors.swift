
// MARK: - Behaviors

public enum Behaviors {
  public struct Cancellation: Error, Equatable { }
  public static let cancellation = Cancellation()
  public enum Throwing { }
}
