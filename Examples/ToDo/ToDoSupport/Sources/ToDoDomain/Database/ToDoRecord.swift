import Foundation
import GRDB

// MARK: - ToDoRecord

/// The ToDo struct.
///
/// Identifiable conformance supports SwiftUI list animations, and type-safe
/// GRDB primary key methods.
/// Equatable conformance supports tests.
struct ToDoRecord: Identifiable, Equatable {
  /// The player id.
  ///
  /// Int64 is the recommended type for auto-incremented database ids.
  /// Use nil for players that are not inserted yet in the database.
  var id: Int64?
  var title: String
  var dueDate: Date?
  var completed: Bool
}

extension ToDoRecord {

  static func new(title: String = "") -> ToDoRecord {
    ToDoRecord(id: nil, title: title, dueDate: nil, completed: false)
  }
}

// MARK: Codable, Hashable, FetchableRecord, MutablePersistableRecord

/// Make ToDo a Codable Record.
///
/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension ToDoRecord: Codable, Hashable, FetchableRecord, MutablePersistableRecord {

  // MARK: Internal

  /// Updates a player id after it has been inserted in the database.
  mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }

  // MARK: Fileprivate

  /// Define database columns from CodingKeys
  fileprivate enum Columns {
    static let title = Column(CodingKeys.title)
    static let dueDate = Column(CodingKeys.dueDate)
    static let completed = Column(CodingKeys.completed)
  }

}

// MARK: - ToDo Database Requests

/// Define some player requests used by the application.
///
/// See
/// <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/recordrecommendedpractices>
extension DerivableRequest<ToDoRecord> {

  func orderedByDueDate() -> Self {
    // Sort by descending completed, and then by title, in a
    // localized case insensitive fashion
    // See https://github.com/groue/GRDB.swift/blob/master/README.md#string-comparison
    order(
      ToDoRecord.Columns.completed.desc,
      ToDoRecord.Columns.title.collating(.localizedCaseInsensitiveCompare)
    )
  }
}
