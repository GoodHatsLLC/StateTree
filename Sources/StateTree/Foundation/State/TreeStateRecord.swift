import Foundation
import Intents
import OrderedCollections

// MARK: - TreeStateRecord

/// The full StateTree state at a moment in time.
public struct TreeStateRecord: Codable {

  // MARK: Lifecycle

  public init() { }

  /// Deserialize state into its usable runtime representation.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Keys.self)
    self.activeIntent = try container.decode(ActiveIntent<NodeID>?.self, forKey: .activeIntent)
    let nodes = try container.decode([NodeRecord].self, forKey: .nodes)
    self.nodes = nodes.reduce(into: OrderedDictionary<NodeID, NodeRecord>()) { acc, curr in
      acc[curr.id] = curr
    }
    if let root = nodes.first {
      self.root = root.id
    }
  }

  /// Deserialize state from a JSON string representation like that created with ``formattedJSON``.
  public init(formattedJSON: String) throws {
    let decoder = JSONDecoder()
    guard let data = formattedJSON.data(using: .utf8)
    else {
      throw StateJSONDecodingError()
    }
    self = try decoder.decode(TreeStateRecord.self, from: data)
  }

  // MARK: Public

  /// Serialize state into readable JSON
  ///
  /// The state can be deserialised with the ``init(formattedJSON:)`` initializer.
  ///
  /// > Tip: The root node will always be first in the state output.
  public var formattedJSON: String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    if
      let data = try? encoder.encode(self),
      let json = String(data: data, encoding: .utf8)
    {
      return json
    } else {
      return ""
    }
  }

  /// Encode the state with a custom encoder.
  ///
  /// > Note: The root node will always be first in the state output.
  ///
  /// > Tip: ``formattedJSON`` allows for easy readable JSON serialization.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(
      keyedBy: Keys.self
    )
    try container.encode(
      nodes.values.elements,
      forKey: .nodes
    )
    try container.encode(
      activeIntent,
      forKey: .activeIntent
    )
  }

  // MARK: Internal

  enum Keys: CodingKey {
    case nodes
    case activeIntent
  }

  var root: NodeID?
  var nodes: OrderedDictionary<NodeID, NodeRecord> = [:]
  var activeIntent: ActiveIntent<NodeID>?

  var nodeIDs: [NodeID] { nodes.keys.elements }
}
