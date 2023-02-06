import Emitter

actor AsyncValue<T> {

  // MARK: Internal

  var value: T {
    get async {
      if let _value {
        return _value
      } else {
        return await withCheckedContinuation { continuation in
          self.continuation = continuation
        }
      }
    }
  }

  func resolve(_ value: T) {
    guard _value == nil
    else {
      return
    }
    _value = value
    continuation?.resume(with: .success(value))
  }

  // MARK: Private

  private var _value: T?
  private var continuation: CheckedContinuation<T, Never>?
}
