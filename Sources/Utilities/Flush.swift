#if DEBUG
public enum Flush {
  public static func tasks(count: Int = 25) async {
    for _ in 0 ..< count {
      _ = await Task<Void, Error> { try await Task<Never, Never>.sleep(nanoseconds: 1_000_000) }
        .result
    }
  }
}
#endif
