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

import Foundation

// MARK: - SipHasher

struct SipHasher {

  public init() {
    self._core = _Core()
  }

  private var _core: _Core

  static func hash(_ string: String) -> String {
    hash(bytes: string.flatMap(\.utf8))
  }

  static func hash(_ input: Data) -> String {
    hash(bytes: input.map { $0 })
  }

  static func hash(bytes: [UInt8]) -> String {
    var hasher = SipHasher()
    for unit in bytes {
      hasher.combine(unit)
    }
    let hash = hasher.finalize()
    let bytes = withUnsafeBytes(of: hash.bigEndian) { Array($0) }
    return bytes.map { String(format: "%02x", $0) }.joined()
  }

}

// MARK: SipHasher._TailBuffer

extension SipHasher {
  internal struct _TailBuffer {

    // MARK: Lifecycle

    @inline(__always)
    internal init() {
      self.value = 0
    }

    @inline(__always)
    internal init(tail: UInt64, byteCount: UInt64) {
      // byteCount can be any value, but we only keep the lower 8 bits.  (The
      // lower three bits specify the count of bytes stored in this buffer.)
      // FIXME: This should be a single expression, but it causes exponential
      // behavior in the expression type checker <rdar://problem/42672946>.
      let shiftedByteCount: UInt64 = ((byteCount & 7) << 3)
      let mask: UInt64 = (1 << shiftedByteCount - 1)
      precondition(tail & ~mask == 0)
      self.value = (byteCount &<< 56 | tail)
    }

    @inline(__always)
    internal init(tail: UInt64, byteCount: Int) {
      self.init(tail: tail, byteCount: UInt64(truncatingIfNeeded: byteCount))
    }

    // MARK: Internal

    /// msb                                                             lsb
    /// +---------+-------+-------+-------+-------+-------+-------+-------+
    /// |byteCount|                 tail (<= 56 bits)                     |
    /// +---------+-------+-------+-------+-------+-------+-------+-------+
    internal var value: UInt64

    internal var tail: UInt64 {
      @inline(__always)
      get { value & ~(0xFF &<< 56) }
    }

    internal var byteCount: UInt64 {
      @inline(__always)
      get { value &>> 56 }
    }

    @inline(__always)
    internal mutating func append(_ bytes: UInt64) -> UInt64 {
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

// MARK: SipHasher._Core

extension SipHasher {
  internal struct _Core {

    // MARK: Lifecycle

    @inline(__always)
    internal init(state: SipHasher._State) {
      self._buffer = _TailBuffer()
      self._state = state
    }

    @inline(__always)
    internal init() {
      self.init(state: _State())
    }

    // MARK: Internal

    @inline(__always)
    internal mutating func combine(_ value: UInt) {
      #if arch(i386) || arch(arm) || arch(arm64_32) || arch(wasm32)
      combine(UInt32(truncatingIfNeeded: value))
      #else
      combine(UInt64(truncatingIfNeeded: value))
      #endif
    }

    @inline(__always)
    internal mutating func combine(_ value: UInt64) {
      _state.compress(_buffer.append(value))
    }

    @inline(__always)
    internal mutating func combine(_ value: UInt32) {
      let value = UInt64(truncatingIfNeeded: value)
      if let chunk = _buffer.append(value, count: 4) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    internal mutating func combine(_ value: UInt16) {
      let value = UInt64(truncatingIfNeeded: value)
      if let chunk = _buffer.append(value, count: 2) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    internal mutating func combine(_ value: UInt8) {
      let value = UInt64(truncatingIfNeeded: value)
      if let chunk = _buffer.append(value, count: 1) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    internal mutating func combine(bytes: UInt64, count: Int) {
      precondition(count >= 0 && count < 8)
      let count = UInt64(truncatingIfNeeded: count)
      if let chunk = _buffer.append(bytes, count: count) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    internal func roundUp(_ offset: UInt, toAlignment alignment: Int) -> UInt {
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
    internal mutating func combine(bytes: UnsafeRawBufferPointer) {
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
    internal mutating func finalize() -> UInt64 {
      _state.finalize(tailAndByteCount: _buffer.value)
    }

    // MARK: Private

    private var _buffer: _TailBuffer
    private var _state: SipHasher._State

  }
}

// MARK: SipHasher._State

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
// This file implements SipHash-2-4 and SipHash-1-3
// (https://131002.net/siphash/).
//
// This file is based on the reference C implementation, which was released
// to public domain by:
//
// * Jean-Philippe Aumasson <jeanphilippe.aumasson@gmail.com>
// * Daniel J. Bernstein <djb@cr.yp.to>
//===----------------------------------------------------------------------===//

extension SipHasher {
  /// FIXME: Remove @usableFromInline and @frozen once SipHasher is resilient.
  /// rdar://problem/38549901
  @usableFromInline @frozen
  internal struct _State {
    /// "somepseudorandomlygeneratedbytes"
    private var v0: UInt64 = 0x736F_6D65_7073_6575
    private var v1: UInt64 = 0x646F_7261_6E64_6F6D
    private var v2: UInt64 = 0x6C79_6765_6E65_7261
    private var v3: UInt64 = 0x7465_6462_7974_6573
    /// The fields below are reserved for future use. They aren't currently used.
    private var v4: UInt64 = 0
    private var v5: UInt64 = 0
    private var v6: UInt64 = 0
    private var v7: UInt64 = 0

    @inline(__always)
    internal init(rawSeed: (UInt64, UInt64)) {
      v3 ^= rawSeed.1
      v2 ^= rawSeed.0
      v1 ^= rawSeed.1
      v0 ^= rawSeed.0
    }
  }
}

extension SipHasher._State {
  @inline(__always)
  private static func _rotateLeft(_ x: UInt64, by amount: UInt64) -> UInt64 {
    (x &<< amount) | (x &>> (64 - amount))
  }

  @inline(__always)
  private mutating func round() {
    v0 = v0 &+ v1
    v1 = SipHasher._State._rotateLeft(v1, by: 13)
    v1 ^= v0
    v0 = SipHasher._State._rotateLeft(v0, by: 32)
    v2 = v2 &+ v3
    v3 = SipHasher._State._rotateLeft(v3, by: 16)
    v3 ^= v2
    v0 = v0 &+ v3
    v3 = SipHasher._State._rotateLeft(v3, by: 21)
    v3 ^= v0
    v2 = v2 &+ v1
    v1 = SipHasher._State._rotateLeft(v1, by: 17)
    v1 ^= v2
    v2 = SipHasher._State._rotateLeft(v2, by: 32)
  }

  @inline(__always)
  private func _extract() -> UInt64 {
    v0 ^ v1 ^ v2 ^ v3
  }
}

extension SipHasher._State {
  @inline(__always)
  internal mutating func compress(_ m: UInt64) {
    v3 ^= m
    round()
    v0 ^= m
  }

  @inline(__always)
  internal mutating func finalize(tailAndByteCount: UInt64) -> UInt64 {
    compress(tailAndByteCount)
    v2 ^= 0xFF
    for _ in 0 ..< 3 {
      round()
    }
    return _extract()
  }
}

extension SipHasher._State {
  @inline(__always)
  internal init() {
    self.init(rawSeed: (UInt64(18_446_744_073_709_551_615), UInt64(65536)))
  }
}

extension SipHasher._Core {

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

extension SipHasher {

  // MARK: Public

  /// Adds the contents of the given buffer to this hasher, mixing it into the
  /// hasher state.
  ///
  /// - Parameter bytes: A raw memory buffer.
  @_effects(releasenone)
  public mutating func combine(bytes: UnsafeRawBufferPointer) {
    _core.combine(bytes: bytes)
  }

  // MARK: Internal

  @_effects(releasenone)
  @usableFromInline
  internal mutating func combine(_ value: UInt) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func combine(_ value: UInt64) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func combine(_ value: UInt32) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func combine(_ value: UInt16) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func combine(_ value: UInt8) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func combine(bytes value: UInt64, count: Int) {
    _core.combine(bytes: value, count: count)
  }

  /// Finalize the hasher state and return the hash value.
  /// Finalizing invalidates the hasher; additional bits cannot be combined
  /// into it, and it cannot be finalized again.
  @_effects(releasenone)
  @usableFromInline
  internal mutating func finalize() -> UInt64 {
    _core.finalize()
  }

}
