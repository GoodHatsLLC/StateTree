@_spi(Implementation)
public struct NodeCapture: Equatable {
  public static func == (lhs: NodeCapture, rhs: NodeCapture) -> Bool {
    lhs.nodeTypeEquals(other: rhs.anyNode)
  }

  private func nodeTypeEquals<N: Node>(other: N) -> Bool {
    if (anyNode as? N) != nil {
      return true
    } else {
      return false
    }
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

  let anyNode: any Node
  let fields: [FieldCapture]
}
