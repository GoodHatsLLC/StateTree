import Bimapping
import Emitter
import Node
import Projection
import SourceLocation
import Utilities

// MARK: - AttachmentPoint

@MainActor
public final class AttachmentPoint<M: Model> {

  init(
    fileID: String,
    line: Int,
    column: Int,
    info: String?
  ) {
    identity = .init(fileID: fileID, line: line, column: column, info: info)
  }

  public var didChange: some Emitter<Void> {
    didChangeSubject
  }

  public func route<Intermediate>(
    _ projection: Projection<Intermediate>,
    into initial: M.State,
    @Bimapping<Intermediate, M.State> stateMap: (
      _ from: Path<Intermediate, Intermediate>,
      _ to: Path<M.State, M.State>
    ) -> Bimapper<Intermediate, M.State>,
    model: @escaping (_ store: Store<M>) -> M
  ) -> Attach<Intermediate, M> {
    .init(
      point: self,
      projection: projection,
      initial: initial,
      stateMap: stateMap(Path(), Path()),
      model: model
    )
  }

  public func route(
    into initial: M.State,
    model: @escaping (_ store: Store<M>) -> M
  ) -> Attach<Void, M> {
    .init(
      point: self,
      projection: .value(()),
      initial: initial,
      stateMap: .none(),
      model: model
    )
  }

  public func route(
    _ projection: Projection<M.State>,
    model: @escaping (_ store: Store<M>) -> M
  ) -> Attach<M.State, M> {
    .init(
      point: self,
      projection: projection,
      initial: projection.value,
      stateMap: .passthrough(),
      model: model
    )
  }

  let identity: SourceLocation

  private(set) var model: M? {
    didSet {
      if model != oldValue {
        didChangeSubject.emit(.value(()))
      }
    }
  }

  func attach(model: M) throws {
    if let attached = self.model {
      throw UnexpectedModelAttached(
        attachmentPoint: self,
        oldModel: attached,
        newModel: model
      )
    }
    self.model = model
  }

  func detach() {
    model = nil
  }

  private let didChangeSubject = PublishSubject<Void>()
}
