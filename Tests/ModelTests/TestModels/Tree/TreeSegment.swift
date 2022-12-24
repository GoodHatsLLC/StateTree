import Disposable
import Model
import Projection

// MARK: - TreeSegment

struct TreeSegment: TreeModel {

  init(
    store: Store<Self>,
    didActivate: @escaping (Self) -> Void = { _ in },
    didUpdate: @escaping (Self) -> Void = { _ in }
  ) {
    _depth = store.proxy(\.depth)
    _name = store.proxy(\.name)
    _localState = store.proxy(\.localState)
    _segment = store.proxy(\.segment)
    _rawState = .init(projectedValue: store)
    didActivateCallback = .init(didActivate)
    didUpdateCallback = .init(didUpdate)
    self.store = store
  }

  // MARK: State
  struct State: TreeModelState {
    var depth = 0
    var name = ""
    var localState = ""
    var segment: TreePath.Segment
  }

  let store: Store<Self>

  // MARK: Annotations
  @DidUpdate<Self> var didUpdate = { this in
    this.didUpdateCallback.ref(this)
  }
  @DidActivate<Self> var didActivate = { this in
    this.didActivateCallback.ref(this)
  }

  public let didUpdateCallback: MutRef<(Self) -> Void>
  public let didActivateCallback: MutRef<(Self) -> Void>

  // MARK: Routes
  @Route<TreeSegment> var lhs
  @Route<TreeSegment> var rhs

  // MARK: State properties
  @RawState<Self> var rawState: State
  @StoreValue var name: String
  @StoreValue var depth: Int
  @StoreValue var localState: String
  @StoreValue var segment: TreePath.Segment

  // MARK: Derived properties
  var type: TreePath.SegmentType {
    segment.segmentType
  }

  // MARK: route(state:)
  func route(state: Projection<State>) -> some Routing {
    if let lhsSegment = state.value.segment.lhs {
      $lhs.route(
        state.mapTreeState(),
        into: TreeSegment.State(segment: lhsSegment)
      ) { from, to in
        from.a <-> to.depth
        from.b <-> to.name
      } model: { store in
        TreeSegment(store: store)
      }
    }

    if let rhsSegment = state.value.segment.rhs {
      $rhs.route(
        state.mapTreeState(),
        into: TreeSegment.State(segment: rhsSegment)
      ) { from, to in
        from.a <-> to.depth
        from.b <-> to.name
      } model: { store in
        TreeSegment(store: store)
      }
    }
  }
}

// MARK: Test Helpers
extension TreeSegment {
  static func start(
    stage: DisposalStage,
    path: TreePath.Segment
  ) throws
    -> TreeSegment
  {
    let root = TreeSegment(
      store: .init(
        rootState: .init(
          segment: path
        )
      )
    )
    try root
      ._startAsRoot(
        config: .defaults,
        annotations: []
      )
      .stage(on: stage)
    return root
  }
}
