import Foundation

// MARK: - URLQueryFragmentConvertible

/// Capable of converting to / from `URLQueryFragment`.
protocol URLQueryFragmentConvertible {
  /// Converts `URLQueryFragment` to self.
  init?(urlQueryFragmentValue value: URLQueryFragment)

  /// Converts self to `URLQueryFragment`.
  var urlQueryFragmentValue: URLQueryFragment { get }
}

// MARK: - String + URLQueryFragmentConvertible

extension String: URLQueryFragmentConvertible {

  // MARK: Lifecycle

  init?(urlQueryFragmentValue value: URLQueryFragment) {
    guard let result = try? value.asURLDecoded() else {
      return nil
    }
    self = result
  }

  // MARK: Internal

  var urlQueryFragmentValue: URLQueryFragment {
    return .urlDecoded(self)
  }
}

extension FixedWidthInteger {

  // MARK: Lifecycle

  /// `URLEncodedFormDataConvertible` conformance.
  init?(urlQueryFragmentValue value: URLQueryFragment) {
    guard
      let decodedString = try? value.asURLDecoded(),
      let fwi = Self(decodedString)
    else {
      return nil
    }
    self = fwi
  }

  // MARK: Internal

  /// `URLEncodedFormDataConvertible` conformance.
  var urlQueryFragmentValue: URLQueryFragment {
    return .urlDecoded(description)
  }
}

// MARK: - Int + URLQueryFragmentConvertible

extension Int: URLQueryFragmentConvertible { }

// MARK: - Int8 + URLQueryFragmentConvertible

extension Int8: URLQueryFragmentConvertible { }

// MARK: - Int16 + URLQueryFragmentConvertible

extension Int16: URLQueryFragmentConvertible { }

// MARK: - Int32 + URLQueryFragmentConvertible

extension Int32: URLQueryFragmentConvertible { }

// MARK: - Int64 + URLQueryFragmentConvertible

extension Int64: URLQueryFragmentConvertible { }

// MARK: - UInt + URLQueryFragmentConvertible

extension UInt: URLQueryFragmentConvertible { }

// MARK: - UInt8 + URLQueryFragmentConvertible

extension UInt8: URLQueryFragmentConvertible { }

// MARK: - UInt16 + URLQueryFragmentConvertible

extension UInt16: URLQueryFragmentConvertible { }

// MARK: - UInt32 + URLQueryFragmentConvertible

extension UInt32: URLQueryFragmentConvertible { }

// MARK: - UInt64 + URLQueryFragmentConvertible

extension UInt64: URLQueryFragmentConvertible { }

extension BinaryFloatingPoint {

  // MARK: Lifecycle

  /// `URLEncodedFormDataConvertible` conformance.
  init?(urlQueryFragmentValue value: URLQueryFragment) {
    guard
      let decodedString = try? value.asURLDecoded(),
      let double = Double(decodedString)
    else {
      return nil
    }
    self = Self(double)
  }

  // MARK: Internal

  /// `URLEncodedFormDataConvertible` conformance.
  var urlQueryFragmentValue: URLQueryFragment {
    return .urlDecoded(Double(self).description)
  }
}

// MARK: - Float + URLQueryFragmentConvertible

extension Float: URLQueryFragmentConvertible { }

// MARK: - Double + URLQueryFragmentConvertible

extension Double: URLQueryFragmentConvertible { }

// MARK: - Bool + URLQueryFragmentConvertible

extension Bool: URLQueryFragmentConvertible {

  // MARK: Lifecycle

  /// `URLEncodedFormDataConvertible` conformance.
  init?(urlQueryFragmentValue value: URLQueryFragment) {
    guard let decodedString = try? value.asURLDecoded() else {
      return nil
    }
    switch decodedString.lowercased() {
    case "1",
         "true": self = true
    case "0",
         "false": self = false
    case "on": self = true
    default: return nil
    }
  }

  // MARK: Internal

  /// `URLEncodedFormDataConvertible` conformance.
  var urlQueryFragmentValue: URLQueryFragment {
    return .urlDecoded(description)
  }
}

// MARK: - Decimal + URLQueryFragmentConvertible

extension Decimal: URLQueryFragmentConvertible {

  // MARK: Lifecycle

  /// `URLEncodedFormDataConvertible` conformance.
  init?(urlQueryFragmentValue value: URLQueryFragment) {
    guard
      let decodedString = try? value.asURLDecoded(),
      let decimal = Decimal(string: decodedString)
    else {
      return nil
    }
    self = decimal
  }

  // MARK: Internal

  /// `URLEncodedFormDataConvertible` conformance.
  var urlQueryFragmentValue: URLQueryFragment {
    return .urlDecoded(description)
  }
}

// MARK: - Date + URLQueryFragmentConvertible

extension Date: URLQueryFragmentConvertible {

  // MARK: Lifecycle

  init?(urlQueryFragmentValue value: URLQueryFragment) {
    guard let double = Double(urlQueryFragmentValue: value) else {
      return nil
    }
    self = Date(timeIntervalSince1970: double)
  }

  // MARK: Internal

  var urlQueryFragmentValue: URLQueryFragment {
    return timeIntervalSince1970.urlQueryFragmentValue
  }
}

// MARK: - URL + URLQueryFragmentConvertible

extension URL: URLQueryFragmentConvertible {

  // MARK: Lifecycle

  init?(urlQueryFragmentValue value: URLQueryFragment) {
    guard let string = String(urlQueryFragmentValue: value) else {
      return nil
    }
    self.init(string: string)
  }

  // MARK: Internal

  var urlQueryFragmentValue: URLQueryFragment {
    absoluteString.urlQueryFragmentValue
  }
}
