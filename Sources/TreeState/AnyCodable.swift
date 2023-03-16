import Foundation

// MARK: - AnyCodable

// https://github.com/Flight-School/AnyCodable/blob/master/LICENSE.md

/// A type-erased `Codable` value.
///
/// The `AnyCodable` type forwards encoding and decoding responsibilities
/// to an underlying value, hiding its specific underlying type.
///
/// You can encode or decode mixed-type values in dictionaries
/// and other collections that require `Encodable` or `Decodable` conformance
/// by declaring their contained type to be `AnyCodable`.
///
/// - SeeAlso: `AnyEncodable`
/// - SeeAlso: `AnyDecodable`
@frozen
public struct AnyCodable: Codable {
  public let value: Any

  public init(_ value: (some Any)?) {
    self.value = value ?? ()
  }
}

// MARK: _AnyEncodable, _AnyDecodable

extension AnyCodable: _AnyEncodable, _AnyDecodable { }

// MARK: Equatable

extension AnyCodable: Equatable {
  public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
    switch (lhs.value, rhs.value) {
    case is (Void, Void):
      return true
    case (let lhs as Bool, let rhs as Bool):
      return lhs == rhs
    case (let lhs as Int, let rhs as Int):
      return lhs == rhs
    case (let lhs as Int8, let rhs as Int8):
      return lhs == rhs
    case (let lhs as Int16, let rhs as Int16):
      return lhs == rhs
    case (let lhs as Int32, let rhs as Int32):
      return lhs == rhs
    case (let lhs as Int64, let rhs as Int64):
      return lhs == rhs
    case (let lhs as UInt, let rhs as UInt):
      return lhs == rhs
    case (let lhs as UInt8, let rhs as UInt8):
      return lhs == rhs
    case (let lhs as UInt16, let rhs as UInt16):
      return lhs == rhs
    case (let lhs as UInt32, let rhs as UInt32):
      return lhs == rhs
    case (let lhs as UInt64, let rhs as UInt64):
      return lhs == rhs
    case (let lhs as Float, let rhs as Float):
      return lhs == rhs
    case (let lhs as Double, let rhs as Double):
      return lhs == rhs
    case (let lhs as String, let rhs as String):
      return lhs == rhs
    case (let lhs as [String: AnyCodable], let rhs as [String: AnyCodable]):
      return lhs == rhs
    case (let lhs as [AnyCodable], let rhs as [AnyCodable]):
      return lhs == rhs
    case (let lhs as [String: Any], let rhs as [String: Any]):
      return NSDictionary(dictionary: lhs) == NSDictionary(dictionary: rhs)
    case (let lhs as [Any], let rhs as [Any]):
      return NSArray(array: lhs) == NSArray(array: rhs)
    case is (NSNull, NSNull):
      return true
    default:
      return false
    }
  }
}

// MARK: CustomStringConvertible

extension AnyCodable: CustomStringConvertible {
  public var description: String {
    switch value {
    case is Void:
      String(describing: nil as Any?)
    case let value as CustomStringConvertible:
      value.description
    default:
      String(describing: value)
    }
  }
}

// MARK: CustomDebugStringConvertible

extension AnyCodable: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch value {
    case let value as CustomDebugStringConvertible:
      "AnyCodable(\(value.debugDescription))"
    default:
      "AnyCodable(\(description))"
    }
  }
}

// MARK: ExpressibleByNilLiteral

extension AnyCodable: ExpressibleByNilLiteral { }

// MARK: ExpressibleByBooleanLiteral

extension AnyCodable: ExpressibleByBooleanLiteral { }

// MARK: ExpressibleByIntegerLiteral

extension AnyCodable: ExpressibleByIntegerLiteral { }

// MARK: ExpressibleByFloatLiteral

extension AnyCodable: ExpressibleByFloatLiteral { }

// MARK: ExpressibleByStringLiteral

extension AnyCodable: ExpressibleByStringLiteral { }

// MARK: ExpressibleByStringInterpolation

extension AnyCodable: ExpressibleByStringInterpolation { }

// MARK: ExpressibleByArrayLiteral

extension AnyCodable: ExpressibleByArrayLiteral { }

// MARK: ExpressibleByDictionaryLiteral

extension AnyCodable: ExpressibleByDictionaryLiteral { }

// MARK: Hashable

extension AnyCodable: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch value {
    case let value as Bool:
      hasher.combine(value)
    case let value as Int:
      hasher.combine(value)
    case let value as Int8:
      hasher.combine(value)
    case let value as Int16:
      hasher.combine(value)
    case let value as Int32:
      hasher.combine(value)
    case let value as Int64:
      hasher.combine(value)
    case let value as UInt:
      hasher.combine(value)
    case let value as UInt8:
      hasher.combine(value)
    case let value as UInt16:
      hasher.combine(value)
    case let value as UInt32:
      hasher.combine(value)
    case let value as UInt64:
      hasher.combine(value)
    case let value as Float:
      hasher.combine(value)
    case let value as Double:
      hasher.combine(value)
    case let value as String:
      hasher.combine(value)
    case let value as [String: AnyCodable]:
      hasher.combine(value)
    case let value as [AnyCodable]:
      hasher.combine(value)
    default:
      break
    }
  }
}
