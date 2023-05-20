@_spi(Implementation)
public struct NodeCapture: Equatable {

  // MARK: Lifecycle

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

  // MARK: Public

  public static func == (lhs: NodeCapture, rhs: NodeCapture) -> Bool {
    lhs.nodeTypeEquals(other: rhs.anyNode)
  }

  // MARK: Internal

  let anyNode: any Node
  let fields: [FieldCapture]

  var routerHandles: [any RouterHandle] {
    fields.compactMap { field in
      switch field {
      case .route(let capture):
        return capture.value.handle
      default:
        return nil
      }
    }
  }

  // MARK: Private

  private func nodeTypeEquals<N: Node>(other _: N) -> Bool {
    if (anyNode as? N) != nil {
      return true
    } else {
      return false
    }
  }

}
