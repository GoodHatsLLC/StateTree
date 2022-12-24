import Foundation

extension Task where Failure == Never, Success == Void {
  static func flush(_ count: Int = 25) async {
    await Self.attemptTaskFlushHack(count: count)
  }
  private static func attemptTaskFlushHack(count: Int) async {
    for _ in 0..<count {
      _ = await Task<Void, Error> {
        try await Task<Never, Never>.sleep(nanoseconds: 1 * USEC_PER_SEC)
      }.result
    }
  }
}
