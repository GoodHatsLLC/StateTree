import Foundation

// MARK: - Route

@MainActor
@propertyWrapper
public struct Route<M: Model> {

  public init(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column
  ) {
    point = .init(fileID: fileID, line: line, column: column, info: String(describing: Self.self))
  }

  public var wrappedValue: M? {
    point.model
  }

  public var point: AttachmentPoint<M>
  public var projectedValue: AttachmentPoint<M> {
    point
  }

}
