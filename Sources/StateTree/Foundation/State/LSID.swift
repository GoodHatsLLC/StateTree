import Foundation

// MARK: - LSID

/// `LSID` — Lifetime-Stable Identity
///
/// An `LSID` represents a value's identity. Values of the same type with the same`LSID` are
/// understood to model the same underlying entity, even if they are not equal. (The entity has
/// changed, but it has maintained its identity).
///
/// `LSID` serves the same purpose as `Identifiable's` `ID`.
public struct LSID: LosslessStringConvertible, TreeState {

  // MARK: Lifecycle

  public init?(_ description: String) {
    if description.isEmpty {
      return nil
    }
    self.description = description
  }

  public init(prefix: String = "", hashable: some Hashable) {
    if let codable = hashable as? any Codable {
      self.init(prefix: prefix, id: codable)
    } else {
      self.init(prefix: prefix, id: "\(prefix)-\(hashable)")
    }
  }

  public init(prefix: String = "", id: some Codable) {
    if let id = id as? any LosslessStringConvertible {
      self.description = "\(prefix)-\(id)"
    } else if
      let data = try? Self.encoder.encode(id),
      let string = String(data: data, encoding: .utf8)
    {
      self.description = "\(prefix)-\(string)"
    } else {
      self.description = "\(prefix)-\(id)"
    }
  }

  public init?(_ description: String?) {
    guard
      let description
    else {
      return nil
    }
    self.init(description)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.description = try container.decode(String.self)
  }

  // MARK: Public

  public let description: String

  public static func from(_ thing: some Identifiable) -> LSID {
    LSID(hashable: thing.id)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }

  // MARK: Private

  private static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    encoder.outputFormatting = .withoutEscapingSlashes
    encoder.dateEncodingStrategy = .iso8601
    encoder.dataEncodingStrategy = .base64
    return encoder
  }()

}
