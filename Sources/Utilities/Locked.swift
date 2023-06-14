// MARK: - Locked

/// A lock wrapper which protects an instance of its generic `T` type with
/// the best available **general purpose**, **non-recursive**, lock available
/// to the platform.
///
/// Use `Locked` only if details of the underlying lock implementation are non-critical.
///
/// > Info: The current implementation prefers locks as follows:
/// 1. `OSAllocatedUnfairLock`
/// 2. `NSLock`
/// 3. `pthread_mutex_t`
public struct Locked<T> {

  // MARK: Lifecycle

  /// Create a non-recursive``Locked`` protecting the given instance of `T`.
  ///
  /// - Parameters:
  ///   - value: the instance to be protected by the lock.
  @inline(__always)
  public init(_ value: T) {
    self.underlying = Self.make(for: value)
  }

  /// Create a non-recursive ``Locked`` that doesn't protect an instance
  /// but instead provides lower level ``lock()`` and ``unlock()`` access.
  ///
  /// - Parameters:
  ///   - value: the instance to be protected by the lock.
  @inline(__always)
  public init() where T == Void {
    self.underlying = Self.make(for: ())
  }

  // MARK: Public

  /// Exclusive `{ get set }` access to the protected value.
  ///
  /// > Note: Use ``withLock(action:)-7qgic`` for atomic
  /// read-evaluate-write access to the underlying variable.
  @inline(__always) public var value: T {
    get {
      withLock { $0 }
    }
    nonmutating _modify {
      let lock = underlying
      lock.lock()
      yield &lock.unsafe_wrapped
      lock.unlock()
    }
    nonmutating set {
      withLock { $0 = newValue }
    }
  }

  /// Take exclusive read-write access to the underlying protected `T` instance returning
  /// any value it returns
  ///
  /// - Parameters:
  ///   - action: A closure accepting an `inout` instance of `T` and optionally returning a value of
  /// `aT`.
  /// - Returns: The instance of `aT` created by the action.
  @inline(__always)
  @discardableResult
  public func withLock<aT>(action: (inout T) throws -> aT) rethrows -> aT {
    let lock = underlying
    lock.lock()
    defer { lock.unlock() }
    return try action(&lock.unsafe_wrapped)
  }

  // MARK: Private

  private let underlying: any LockType<T>
}

extension Locked where T == Void {
  /// Take exclusive access to the lock while executing the passed closure returning
  /// any value it returns.
  ///
  /// - Parameters:
  ///   - action: A closure accepting an `inout` instance of `T` and optionally returning a value of
  /// `aT`.
  /// - Returns: The instance of `aT` created by the action.
  @inline(__always)
  @discardableResult
  public func withLock<P>(action: () throws -> P) rethrows -> P {
    let lock = underlying
    lock.lock()
    defer { lock.unlock() }
    return try action()
  }

  /// Take exclusive access to the lock.
  ///
  /// Prefer ``withLock(action:)-7ntrz``.
  @inline(__always)
  public func lock() {
    underlying.lock()
  }

  /// Release exclusive access taken with ``lock()``
  @inline(__always)
  public func unlock() {
    underlying.unlock()
  }
}

// MARK: Sendable

extension Locked: @unchecked Sendable where T: Sendable { }

extension Locked {
  @inline(__always)
  fileprivate static func make(for value: T) -> some LockType<T> {
    #if canImport(os)
    if #available(iOS 16, macOS 13, tvOS 16, macCatalyst 16, watchOS 9, *) {
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

// MARK: - LockType

private protocol LockType<T>: AnyObject {
  associatedtype T
  @inline(__always)
  func lock()
  @inline(__always)
  func unlock()
  @inline(__always) var unsafe_wrapped: T { get set }
}

#if canImport(Foundation)
import Foundation
private final class NSLocked<T>: LockType {

  // MARK: Lifecycle

  @inline(__always)
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

  @inline(__always)
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

  @inline(__always)
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
