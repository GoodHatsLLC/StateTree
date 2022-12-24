import Foundation
import StateTree

private let NSEC_PER_DAY: Double = 60 * 60 * 24

// MARK: - DueDateData

public struct DueDateData: ModelState, Metadata {
  public var date: Date?

  public var type: ToDoMetadata { .dueDate }

  func matches(query: SearchQuery) -> Bool {
    switch query {
    case .none:
      return true
    case .toggle:
      return false
    case .date(let date):
      guard let dueDate = self.date
      else {
        return false
      }
      guard
        let searchDay = Calendar.current
          .dateComponents(
            [.day],
            from: date
          ).day,
        let dueDay = Calendar.current
          .dateComponents(
            [.day],
            from: dueDate
          ).day
      else {
        return false
      }

      let interval = dueDate.timeIntervalSince(date)
      let absInterval = max(interval, -interval)
      let withinADay = absInterval < NSEC_PER_DAY
      let onSameCalendarDay = searchDay == dueDay
      return withinADay && onSameCalendarDay
    case .text:
      return false
    }
  }
}
