import Model
import Projection

// MARK: - TreeModelState

protocol TreeModelState: ModelState {
  var depth: Int { get set }
  var name: String { get set }
  var segment: TreePath.Segment { get set }
}

// MARK: - TreeModel

protocol TreeModel: Model where State: TreeModelState {}
extension Projection where Value: TreeModelState {
  func mapTreeState() -> Projection<Tuple.Size3<Int, String, TreePath.Segment>> {
    let this = self
    return this.map { upstream in
      upstream.depth + 1
    } upwards: { varUpstream, downstream in
      varUpstream.depth = downstream - 1
    }
    .joinTwo(this.name, this.segment)
  }
}
