import Foundation

// MARK: - RouteList

@MainActor
@propertyWrapper
public struct RouteList<M: Model> {

  public init(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column
  ) {
    point = .init(fileID: fileID, line: line, column: column, info: String(describing: Self.self))
  }

  public var wrappedValue: [M] {
    point.models
  }

  public var point: ListAttachmentPoint<M>
  public var projectedValue: ListAttachmentPoint<M> {
    point
  }

}
