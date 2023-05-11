import TreeActor

@TreeActor
protocol ChangeManager: AnyObject {
  func flush(dependentChanges changes: TreeChanges)
}
