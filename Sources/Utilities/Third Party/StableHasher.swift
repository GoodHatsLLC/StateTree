// MARK: - StableHasher

// StableHasher is a stable reimplementation of the hashing algorithm Swift's native Hasher uses.
// It is derived from from SipHasher and Swift's native Hasher, which both implement the SipHash
// algorithm https://131002.net/siphash/

//  The MIT License (MIT)
//  Copyright (c) 2016 Károly Lőrentey
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
//  and associated documentation files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//  https://github.com/attaswift/SipHash

// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

import Foundation

// MARK: - StableHasher

/// `StableHasher.hash(encodable:)` returns a stably hashed string.
///
/// `StableHasher ` is derived from from SipHasher and Swift's native Hasher, which both implement
/// the SipHash
/// algorithm https://131002.net/siphash/
public struct StableHasher {

  // MARK: Lifecycle

  init() {
    self.core = Core()
  }

  // MARK: Public

  public static func hash(encodable: some Encodable) throws -> String {
    let data = try JSONEncoder().encode(encodable)
    return hash(bytes: data.map { $0 })
  }

  public static func hash(_ string: String) -> String {
    try! hash(encodable: string)
  }

  public static func hash(_ int: Int) -> String {
    try! hash(encodable: int)
  }

  public static func hash(_ double: Double) -> String {
    try! hash(encodable: double)
  }

  public static func hash(_ bool: Bool) -> String {
    try! hash(encodable: bool)
  }

  public static func hash(_ data: Data) -> String {
    try! hash(encodable: data)
  }

  // MARK: Internal

  static func hash(bytes: [UInt8]) -> String {
    var hasher = StableHasher()
    for unit in bytes {
      hasher.combine(unit)
    }
    let hash = hasher.finalize()
    let bytes = withUnsafeBytes(of: hash.bigEndian) { Array($0) }
    return bytes.map { String(format: "%02x", $0) }.joined()
  }

  // MARK: Private

  private var core: Core

}

// MARK: StableHasher.TailBuffer

extension StableHasher {
  struct TailBuffer {

    // MARK: Lifecycle

    @inline(__always)
    init() {
      self.value = 0
    }

    @inline(__always)
    init(tail: UInt64, byteCount: UInt64) {
      let shiftedByteCount: UInt64 = ((byteCount & 7) << 3)
      let mask: UInt64 = (1 << shiftedByteCount - 1)
      precondition(tail & ~mask == 0)
      self.value = (byteCount &<< 56 | tail)
    }

    @inline(__always)
    init(tail: UInt64, byteCount: Int) {
      self.init(tail: tail, byteCount: UInt64(truncatingIfNeeded: byteCount))
    }

    // MARK: Internal

    /// ```
    /// msb                                                             lsb
    /// +---------+-------+-------+-------+-------+-------+-------+-------+
    /// |byteCount|                 tail (<= 56 bits)                     |
    /// +---------+-------+-------+-------+-------+-------+-------+-------+
    /// ```
    var value: UInt64

    var tail: UInt64 {
      @inline(__always)
      get { value & ~(0xFF &<< 56) }
    }

    var byteCount: UInt64 {
      @inline(__always)
      get { value &>> 56 }
    }

    @inline(__always)
    mutating func append(_ bytes: UInt64) -> UInt64 {
      let c = byteCount & 7
      if c == 0 {
        value = value &+ (8 &<< 56)
        return bytes
      }
      let shift = c &<< 3
      let chunk = tail | (bytes &<< shift)
      value = (((value &>> 56) &+ 8) &<< 56) | (bytes &>> (64 - shift))
      return chunk
    }

    @inline(__always)
    internal
    mutating func append(_ bytes: UInt64, count: UInt64) -> UInt64? {
      precondition(count >= 0 && count < 8)
      precondition(bytes & ~((1 &<< (count &<< 3)) &- 1) == 0)
      let c = byteCount & 7
      let shift = c &<< 3
      if c + count < 8 {
        value = (value | (bytes &<< shift)) &+ (count &<< 56)
        return nil
      }
      let chunk = tail | (bytes &<< shift)
      value = ((value &>> 56) &+ count) &<< 56
      if c + count > 8 {
        value |= bytes &>> (64 - shift)
      }
      return chunk
    }
  }
}

// MARK: StableHasher.Core

extension StableHasher {
  struct Core {

    // MARK: Lifecycle

    @inline(__always)
    init(state: StableHasher.State) {
      self._buffer = TailBuffer()
      self._state = state
    }

    @inline(__always)
    init() {
      self.init(state: State())
    }

    // MARK: Internal

    @inline(__always)
    mutating func combine(_ value: UInt) {
      #if arch(i386) || arch(arm) || arch(arm64_32) || arch(wasm32)
      combine(UInt32(truncatingIfNeeded: value))
      #else
      combine(UInt64(truncatingIfNeeded: value))
      #endif
    }

    @inline(__always)
    mutating func combine(_ value: UInt64) {
      _state.compress(_buffer.append(value))
    }

    @inline(__always)
    mutating func combine(_ value: UInt32) {
      let value = UInt64(truncatingIfNeeded: value)
      if let chunk = _buffer.append(value, count: 4) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    mutating func combine(_ value: UInt16) {
      let value = UInt64(truncatingIfNeeded: value)
      if let chunk = _buffer.append(value, count: 2) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    mutating func combine(_ value: UInt8) {
      let value = UInt64(truncatingIfNeeded: value)
      if let chunk = _buffer.append(value, count: 1) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    mutating func combine(bytes: UInt64, count: Int) {
      precondition(count >= 0 && count < 8)
      let count = UInt64(truncatingIfNeeded: count)
      if let chunk = _buffer.append(bytes, count: count) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    func roundUp(_ offset: UInt, toAlignment alignment: Int) -> UInt {
      precondition(alignment > 0)
      precondition(_isPowerOf2(alignment))
      // Note, given that offset is >= 0, and alignment > 0, we don't
      // need to underflow check the -1, as it can never underflow.
      let x = offset + UInt(bitPattern: alignment) &- 1
      // Note, as alignment is a power of 2, we'll use masking to efficiently
      // get the aligned value
      return x & ~(UInt(bitPattern: alignment) &- 1)
    }

    @inline(__always)
    mutating func combine(bytes: UnsafeRawBufferPointer) {
      var remaining = bytes.count
      guard remaining > 0 else {
        return
      }
      var data = bytes.baseAddress!

      // Load first unaligned partial word of data
      do {
        let start = UInt(bitPattern: data)
        let end = roundUp(start, toAlignment: MemoryLayout<UInt64>.alignment)
        let c = min(remaining, Int(end - start))
        if c > 0 {
          let chunk = loadPartialUnalignedUInt64LE(data, byteCount: c)
          combine(bytes: chunk, count: c)
          data += c
          remaining -= c
        }
      }
      precondition(
        remaining == 0 ||
          Int(bitPattern: data) & (MemoryLayout<UInt64>.alignment - 1) == 0
      )

      // Load as many aligned words as there are in the input buffer
      while remaining >= MemoryLayout<UInt64>.size {
        combine(UInt64(littleEndian: data.load(as: UInt64.self)))
        data += MemoryLayout<UInt64>.size
        remaining -= MemoryLayout<UInt64>.size
      }

      // Load last partial word of data
      precondition(remaining >= 0 && remaining < 8)
      if remaining > 0 {
        let chunk = loadPartialUnalignedUInt64LE(data, byteCount: remaining)
        combine(bytes: chunk, count: remaining)
      }
    }

    @inline(__always)
    mutating func finalize() -> UInt64 {
      _state.finalize(tailAndByteCount: _buffer.value)
    }

    // MARK: Private

    private var _buffer: TailBuffer
    private var _state: StableHasher.State

  }
}

// MARK: StableHasher.State

extension StableHasher {
  struct State {
    private var v0: UInt64 = 0x736F_6D65_7073_6575
    private var v1: UInt64 = 0x646F_7261_6E64_6F6D
    private var v2: UInt64 = 0x6C79_6765_6E65_7261
    private var v3: UInt64 = 0x7465_6462_7974_6573

    @inline(__always)
    init(rawSeed: (UInt64, UInt64)) {
      v3 ^= rawSeed.1
      v2 ^= rawSeed.0
      v1 ^= rawSeed.1
      v0 ^= rawSeed.0
    }
  }
}

extension StableHasher.State {
  @inline(__always)
  private static func rotateLeft(_ x: UInt64, by amount: UInt64) -> UInt64 {
    (x &<< amount) | (x &>> (64 - amount))
  }

  @inline(__always)
  private mutating func round() {
    v0 = v0 &+ v1
    v1 = StableHasher.State.rotateLeft(v1, by: 13)
    v1 ^= v0
    v0 = StableHasher.State.rotateLeft(v0, by: 32)
    v2 = v2 &+ v3
    v3 = StableHasher.State.rotateLeft(v3, by: 16)
    v3 ^= v2
    v0 = v0 &+ v3
    v3 = StableHasher.State.rotateLeft(v3, by: 21)
    v3 ^= v0
    v2 = v2 &+ v1
    v1 = StableHasher.State.rotateLeft(v1, by: 17)
    v1 ^= v2
    v2 = StableHasher.State.rotateLeft(v2, by: 32)
  }

  @inline(__always)
  private func _extract() -> UInt64 {
    v0 ^ v1 ^ v2 ^ v3
  }
}

extension StableHasher.State {
  @inline(__always)
  mutating func compress(_ m: UInt64) {
    v3 ^= m
    round()
    v0 ^= m
  }

  @inline(__always)
  mutating func finalize(tailAndByteCount: UInt64) -> UInt64 {
    compress(tailAndByteCount)
    v2 ^= 0xFF
    for _ in 0 ..< 3 {
      round()
    }
    return _extract()
  }
}

extension StableHasher.State {
  @inline(__always)
  init() {
    self.init(rawSeed: (UInt64(18_446_744_073_709_551_615), UInt64(65536)))
  }
}

extension StableHasher.Core {

  fileprivate func loadPartialUnalignedUInt64LE(
    _ p: UnsafeRawPointer,
    byteCount: Int
  )
    -> UInt64
  {
    var result: UInt64 = 0
    switch byteCount {
    case 7:
      result |= UInt64(p.load(fromByteOffset: 6, as: UInt8.self)) &<< 48
      fallthrough
    case 6:
      result |= UInt64(p.load(fromByteOffset: 5, as: UInt8.self)) &<< 40
      fallthrough
    case 5:
      result |= UInt64(p.load(fromByteOffset: 4, as: UInt8.self)) &<< 32
      fallthrough
    case 4:
      result |= UInt64(p.load(fromByteOffset: 3, as: UInt8.self)) &<< 24
      fallthrough
    case 3:
      result |= UInt64(p.load(fromByteOffset: 2, as: UInt8.self)) &<< 16
      fallthrough
    case 2:
      result |= UInt64(p.load(fromByteOffset: 1, as: UInt8.self)) &<< 8
      fallthrough
    case 1:
      result |= UInt64(p.load(fromByteOffset: 0, as: UInt8.self))
      fallthrough
    case 0:
      return result
    default:
      preconditionFailure()
    }
  }
}

extension StableHasher {

  // MARK: Public

  /// Adds the contents of the given buffer to this hasher, mixing it into the
  /// hasher state.
  ///
  /// - Parameter bytes: A raw memory buffer.
  @_effects(releasenone)
  public mutating func combine(bytes: UnsafeRawBufferPointer) {
    core.combine(bytes: bytes)
  }

  // MARK: Internal

  @_effects(releasenone)
  @usableFromInline
  mutating func combine(_ value: UInt) {
    core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  mutating func combine(_ value: UInt64) {
    core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  mutating func combine(_ value: UInt32) {
    core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  mutating func combine(_ value: UInt16) {
    core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  mutating func combine(_ value: UInt8) {
    core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  mutating func combine(bytes value: UInt64, count: Int) {
    core.combine(bytes: value, count: count)
  }

  /// Finalize the hasher state and return the hash value.
  /// Finalizing invalidates the hasher; additional bits cannot be combined
  /// into it, and it cannot be finalized again.
  @_effects(releasenone)
  @usableFromInline
  mutating func finalize() -> UInt64 {
    core.finalize()
  }

}
