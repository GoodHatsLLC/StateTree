import Foundation
import TreeState

// MARK: - UpdateStats

public struct UpdateStats: TreeState {

  // MARK: Public

  /// Update event duration info.
  public struct Durations {
    let stats: UpdateStats
    /// Cumulative duration of all node updates.
    public var nodeUpdates: TimeInterval {
      stats.timeElapsed
    }
  }

  /// A timer measure node update times.
  public struct UpdateTimer {
    let startTime = ProcessInfo.processInfo.systemUptime
    func stop() -> TimeInterval {
      ProcessInfo.processInfo.systemUptime - startTime
    }
  }

  /// Debug/Testing info: Counts of types of node updates.
  public struct Counts {

    // MARK: Public

    /// The number of times nodes have been started.
    public var nodeStarts: Int {
      stats.nodeMap.values.reduce(0) { partialResult, count in
        partialResult + count.starts
      }
    }

    /// The number of times nodes have been stopped.
    public var nodeStops: Int {
      stats.nodeMap.values.reduce(0) { partialResult, count in
        partialResult + count.stops
      }
    }

    /// The number of times nodes have been updated, Including repeated updates to the same node.
    public var nodeUpdates: Int {
      stats.nodeMap.values.reduce(0) { partialResult, count in
        partialResult + count.updates
      }
    }

    /// The number of times nodes have had a start, stop, or update events. Including repeated
    /// updates to the same node.
    public var allNodeEvents: Int {
      stats.nodeMap.values.reduce(0) { partialResult, count in
        partialResult + count.starts + count.stops + count.updates
      }
    }

    /// The number of nodes affected by updates.
    public var uniqueTouchedNodes: Int {
      stats.nodeMap.keys.count
    }

    // MARK: Internal

    let stats: UpdateStats

  }

  /// Debug/Testing info: Counts of types of node updates.
  public var counts: Counts {
    .init(stats: self)
  }

  /// Debug/Testing info: Durations of node updates.
  public var durations: Durations {
    .init(stats: self)
  }

  // MARK: Internal

  struct NodeStats: TreeState {
    let nodeID: NodeID
    var starts: Int = 0
    var updates: Int = 0
    var stops: Int = 0

    func merged(with other: NodeStats) -> NodeStats {
      assert(other.nodeID == nodeID)
      var copy = self
      copy.starts += other.starts
      copy.stops += other.stops
      copy.updates += other.updates
      return copy
    }
  }

  var nodeMap: [NodeID: NodeStats] = [:]
  var timeElapsed: TimeInterval = 0

  func startedTimer() -> UpdateTimer {
    UpdateTimer()
  }

  mutating func recordTimeElapsed(from timer: UpdateTimer) {
    timeElapsed += timer.stop()
  }

  func merged(with other: UpdateStats) -> UpdateStats {
    var copy = self
    copy.nodeMap.merge(other.nodeMap) { lhs, rhs in
      lhs.merged(with: rhs)
    }
    copy.timeElapsed += other.timeElapsed
    return copy
  }
}
