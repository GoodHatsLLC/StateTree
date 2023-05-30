import Behavior
import TreeActor
import Utilities

// MARK: - StateApplier

@TreeActor
final class StateApplier: ApplicationManager {

  // MARK: Lifecycle

  nonisolated init(
    newState: TreeStateRecord,
    stateStorage: StateStorage,
    scopeStorage: ScopeStorage
  ) {
    self.stateStorage = stateStorage
    self.scopeStorage = scopeStorage
    self.newState = newState
  }

  // MARK: Internal

  private(set) var isFlushing: Bool = false

  func flush() throws -> (events: [NodeEvent], stats: UpdateStats) {
    assert(!isFlushing, "flush should never be called when another flush is in progress")
    isFlushing = true
    defer { isFlushing = false }
    return try updateScopes()
  }

  // MARK: Private

  private let stateStorage: StateStorage
  private let scopeStorage: ScopeStorage
  private let newState: TreeStateRecord

  private func updateScopes() throws -> (events: [NodeEvent], stats: UpdateStats) {
    var updateCollector = UpdateCollector()
    let timer = updateCollector.stats.startedTimer()

    var priorityQueue = PriorityQueue(
      type: AnyScope.self,
      prioritizeBy: \.depth,
      uniqueBy: \.nid
    )

    while !priorityQueue.isEmpty {
      // Forward the root-most node.
      if
        let scope = priorityQueue.min,
        scope.requiresReadying
      {
        // if true, the node is now clean
        if
          try scope.stepTowardsReady(),
          let scope = priorityQueue.popMin()
        {
          updateCollector.updated(id: scope.nid, depth: scope.depth)
        }
      }
      // Check if the deepest scope requires 'finalization'
      // actions to progress it further towards stopping.
      else if
        let scope = priorityQueue.max,
        scope.requiresFinishing
      {
        // Act, and remove the scope if fully finished.
        if
          try scope.stepTowardsFinished(),
          let scope = priorityQueue.popMax()
        {
          updateCollector.stopped(id: scope.nid, depth: scope.depth)
          continue
        }
      }
      // When the deepest changed scope needs to be forwarded and
      // the changed scope closest to the root needs to be finished
      // neither scope has yet been removed from the queue.
      //
      // Since a scope can only be in the queue if it still needs progress
      // towards either being fully updated or removed we can finalize
      // the root-most scope to avoid an impasse.
      else if
        let scope = priorityQueue.min,
        scope.requiresFinishing
      {
        // if true, the node is now clean
        if
          try scope.stepTowardsFinished(),
          let scope = priorityQueue.popMin()
        {
          updateCollector.stopped(id: scope.nid, depth: scope.depth)
        }
      }
      // If no change to the queue are possible the queue must be empty.
      else {
        assert(priorityQueue.isEmpty)
      }
    }

    updateCollector.stats.recordTimeElapsed(from: timer)

    // Return the list of updated nodes to fire notifications
    // to the UI layer for.
    return updateCollector.collectChanges()
  }

}
