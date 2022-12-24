import Dependencies
import Foundation

// MARK: - LogPrinterKey

struct LogPrinterKey: DependencyKey {
  static let defaultValue = LogPrinter()
}

// MARK: - RatePrinterKey

struct RatePrinterKey: DependencyKey {
  static let defaultValue = RatePrinter(
    logPrinter: DependencyValues.defaults.logger
  )
}

extension DependencyValues {
  public var logger: LogPrinter {
    get { self[LogPrinterKey.self] }
    set { self[LogPrinterKey.self] = newValue }
  }

  public var logRate: RatePrinter {
    get { self[RatePrinterKey.self] }
    set { self[RatePrinterKey.self] = newValue }
  }
}
