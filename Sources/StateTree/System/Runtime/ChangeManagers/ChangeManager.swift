@TreeActor
protocol ChangeManager: AnyObject {
  func flush(dependentChanges changes: TreeChanges)
  func register(metadata: StateChangeMetadata?)
}
