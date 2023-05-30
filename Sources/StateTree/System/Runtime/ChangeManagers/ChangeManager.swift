import TreeActor

// MARK: - ChangeManager

@TreeActor
protocol ChangeManager: AnyObject {
  func flush() throws -> (events: [NodeEvent], stats: UpdateStats)
  func flush(dependentChanges changes: TreeChanges)
}

// MARK: - ApplicationManager

@TreeActor
protocol ApplicationManager: AnyObject {
  func flush() throws -> (events: [NodeEvent], stats: UpdateStats)
}
