import Bimapping
import Node
import Projection
import SourceLocation
import Utilities

// MARK: - ListAttachmentPoint

@MainActor
public final class ListAttachmentPoint<M: Model> {

  init(
    fileID: String,
    line: Int,
    column: Int,
    info: String?
  ) {
    identity = .init(fileID: fileID, line: line, column: column, info: info)
  }

  public func routeForEach<I: Identifiable>(
    _ collection: Projection<[I]>,
    into initial: M.State,
    @Bimapping<I, M.State> stateMap: (_ from: Path<I, I>, _ to: Path<M.State, M.State>) -> Bimapper<
      I, M.State
    >,
    model: @escaping (_ item: I, _ store: Store<M>) -> M
  ) -> ListAttach<M, I> {
    let biMap = stateMap(Path(), Path())
    return .init(
      point: self,
      collection: collection,
      into: initial,
      with: biMap,
      model: model
    )
  }

  public func routeForEach<I: Identifiable>(
    _ collection: Projection<[I]>,
    model: @escaping (_ item: I, _ store: Store<M>) -> M
  ) -> ListAttach<M, I> where I == M.State {
    .init(
      point: self,
      collection: collection,
      model: model
    )
  }

  let identity: SourceLocation

  var models: [M] = []

}
