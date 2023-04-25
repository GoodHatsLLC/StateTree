import Foundation
import StateTree

// MARK: - Tag

public struct Tag: Node, Identifiable {

  init(id: UUID) {
    self.id = id
  }

  // MARK: Public

  public let id: UUID
  @Value public var title: String = ""

  public var rules: some Rules { () }

}
