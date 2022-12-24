import Disposable
import Foundation
import Logging

// MARK: - RatePrinter

@MainActor
public final class RatePrinter {

  nonisolated init(logPrinter: LogPrinter) {
    logger = logPrinter
  }

  public func start() throws -> AnyDisposable {
    guard !isStarted
    else {
      throw AlreadyStartedError()
    }
    logger.log("⏱️", message: "StateTree rate logger started")
    isStarted = true
    return AnyDisposable {
      self.isStarted = false
      self.logger.log("⏱️", message: "StateTree rate logger stopped")
    }
  }

  public func log(id: StaticString, value: Double) {
    guard isStarted
    else {
      return
    }
    if !active {
      active = true
      DispatchQueue.main.schedule(after: .init(.now()), interval: .milliseconds(100)) {
        self.output()
        self.clear()
      }
      .erase()
      .stageOneByLocation()
    }
    register(id: "\(id)", value: value)
  }

  struct AlreadyStartedError: Error {}

  private let logger: LogPrinter

  private var isStarted = false
  private var countMap: [String: Int] = [:]
  private var valueMap: [String: Double] = [:]
  private var active = false

  private func register(id: String, value: Double? = nil) {
    let current = countMap[id, default: 0]
    countMap[id] = current + 1
    if let value {
      let currValue = valueMap[id] ?? 0
      valueMap[id] = currValue + value
    }
  }

  private func output() {
    for (k, v) in countMap {
      let time = valueMap[k].map { $0.formattedMilliseconds } ?? ""
      logger.log("⏱️", message: "\(time) \(v)")
    }
  }

  private func clear() {
    countMap.removeAll()
    valueMap.removeAll()
    active = false
  }

}

extension TimeInterval {
  fileprivate var formattedMilliseconds: String {
    let micro = Int((self * 1_000_000).rounded())
    let string = "\(micro)"
    let msString = string.dropLast(3)
    let decimalPoint = string.suffix(3)
    return "\(msString).\(decimalPoint)ms"
  }
}
