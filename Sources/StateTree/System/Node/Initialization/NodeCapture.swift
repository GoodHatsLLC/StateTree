@_spi(Implementation)
public struct NodeCapture: Equatable {
  public static func == (lhs: NodeCapture, rhs: NodeCapture) -> Bool {
    lhs.fields == rhs.fields
  }

  init(_ node: some Node) {
    self.anyNode = node
    let mirror = Mirror(reflecting: node)
    self.fields = mirror
      .children
      .enumerated()
      .map { offset, child in
        FieldCapture(child, offset: offset)
      }
  }

  var uniqueIdentity: String? {
    anyNode.uniqueIdentity
  }

  let anyNode: any Node
  let fields: [FieldCapture]
}
