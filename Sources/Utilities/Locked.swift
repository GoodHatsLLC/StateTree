// MARK: - Locked

/// A lock wrapper which protects an instance of its generic `T` type with
/// the best **general purpose** and **non-recursive** lock available
/// in the compiled environment
public struct Locked<T>: LockedValue {

  // MARK: Lifecycle

  /// Create a new ``Locked`` protecting the given instance.
  public init(_ value: T) {
    let lock = Self.make(for: value)
    self.underlying = lock
    self.withLockImpl = { act in
      lock.lock()
      defer { lock.unlock() }
      return act(&lock.unsafe_wrapped)
    }
  }

  // MARK: Public

  /// Exclusive `{ get set }` access to the protected value.
  ///
  /// > Note: Use ``withLock(_:)`` instead of this accessor when
  /// atomic read-evaluate-write access is needed.
  public var value: T {
    get {
      withLock { $0 }
    }
    nonmutating _modify {
      underlying.lock()
      yield &underlying.unsafe_wrapped
      underlying.unlock()
    }
    nonmutating set {
      withLock { $0 = newValue }
    }
  }

  /// Take exclusive read-write access to the underlying protected `T` instance returning
  /// any value returned by the given closure.
  @discardableResult
  public func withLock<aT>(_ act: (inout T) -> aT) -> aT {
    withLockImpl(act) as! aT
  }

  // MARK: Private

  private let withLockImpl: ((inout T) -> Any) -> Any
  private let underlying: any LockType<T>

}

// MARK: Sendable

extension Locked: @unchecked Sendable where T: Sendable { }

extension Locked {
  @inline(__always)
  fileprivate static func make(for value: T) -> some LockType<T> {
    #if canImport(os)
    if #available(iOS 16, macOS 13, *) {
      return OSUnfairLocked(value)
    } else {
      return NSLocked(value)
    }
    #elseif canImport(Foundation)
    return NSLocked(value)
    #else
    return PThreadLock(value)
    #endif
  }
}

// MARK: - LockedValue

private protocol LockedValue<T> {
  associatedtype T
  @discardableResult
  init(_: T)
  func withLock<aT>(_: (inout T) -> aT) -> aT
}

// MARK: - LockType

private protocol LockType<T>: AnyObject {
  associatedtype T
  @inline(__always)
  func lock()
  @inline(__always)
  func unlock()
  var unsafe_wrapped: T { get set }
}

#if canImport(Foundation)
import Foundation
private final class NSLocked<T>: LockType {

  // MARK: Lifecycle

  fileprivate init(_ value: T) {
    self.unsafe_wrapped = value
  }

  // MARK: Fileprivate

  fileprivate var unsafe_wrapped: T

  @inline(__always)
  fileprivate func lock() {
    nslock.lock()
  }

  @inline(__always)
  fileprivate func unlock() {
    nslock.unlock()
  }

  // MARK: Private

  private let nslock = NSLock()
}
#endif

#if canImport(os)
import os
@available(iOS 16, macOS 13, *)
private final class OSUnfairLocked<T>: LockType {

  // MARK: Lifecycle

  fileprivate init(_ value: T) {
    self.oslock = .init(initialState: ())
    self.unsafe_wrapped = value
  }

  // MARK: Fileprivate

  fileprivate var unsafe_wrapped: T

  @inline(__always)
  fileprivate func lock() {
    oslock.lock()
  }

  @inline(__always)
  fileprivate func unlock() {
    oslock.unlock()
  }

  // MARK: Private

  private let oslock: OSAllocatedUnfairLock<Void>
}
#endif

// MARK: - PThreadLock

private final class PThreadLock<T>: LockType {

  // MARK: Lifecycle

  fileprivate init(_ value: T) {
    self.unsafe_wrapped = value
  }

  // MARK: Fileprivate

  fileprivate var unsafe_wrapped: T

  @inline(__always)
  fileprivate func lock() {
    pthread_mutex_lock(&mutex)
  }

  @inline(__always)
  fileprivate func unlock() {
    pthread_mutex_unlock(&mutex)
  }

  // MARK: Private

  private var mutex = pthread_mutex_t()
}