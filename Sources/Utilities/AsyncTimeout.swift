import Foundation

extension Async {

  public struct Timeout: Error { }

  @discardableResult
  public static func timeout<T>(
    seconds: Double?,
    action: @escaping () async -> T
  ) async -> Result<T, Timeout> {
    let signal = Async.Value<Result<T, Timeout>>()
    Task {
      let x = await action()
      await signal.resolve(to: .success(x))
    }
    if let seconds {
      Task {
        try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
        await signal.resolve(to: .failure(Timeout()))
      }
    }
    return await signal.value
  }

  @discardableResult
  public static func timeout<T>(
    seconds: Double?,
    action: @escaping () async throws -> T
  ) async -> Result<Result<T, Error>, Timeout> {
    let signal = Async.Value<Result<Result<T, Error>, Timeout>>()
    Task {
      do {
        let x = try await action()
        await signal.resolve(to: .success(.success(x)))
      } catch {
        await signal.resolve(to: .success(.failure(error)))
      }
    }
    if let seconds {
      Task {
        try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
        await signal.resolve(to: .failure(Timeout()))
      }
    }
    return await signal.value
  }
}
