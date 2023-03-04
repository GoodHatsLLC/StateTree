import Foundation

public struct Locked<Value>: @unchecked Sendable {
  public init(_ value: Value) {
    self.ref = Ref(value: value)
  }

  private let lock = NSLock()
  private let ref: Ref<Value>
  @discardableResult
  public func withLock<Output>(_ action: (_ value: inout Value) throws -> Output) rethrows
    -> Output
  {
    lock.lock()
    let output = try action(&ref.value)
    lock.unlock()
    return output
  }
}
