import Disposable
import DisposableInterface
import Logging
import SourceLocation

// MARK: - LogLevel

public enum LogLevel: Int, Comparable {
  public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  case info = 1
  case warn = 2
  case error = 3
  case critical = 4
}

// MARK: - LogPrinter

@MainActor
public final class LogPrinter {

  nonisolated init() {}

  public func start(logThreshold: LogLevel) throws -> AnyDisposable {
    guard !isStarted
    else {
      throw AlreadyStartedError()
    }
    isStarted = true
    self.logThreshold = logThreshold
    if logThreshold <= .info {
      logger.info("🌳 StateTree event logger started")
    }
    return AnyDisposable {
      self.logThreshold = .critical
      self.isStarted = false
      if logThreshold <= .info {
        self.logger.info("🌳 StateTree event logger ended")
      }
    }
  }

  public func log(
    file: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ identifier: String = "🪵",
    message: String,
    _ payload: Any?...
  ) {
    if isStarted, logThreshold <= .info {
      let codeLoc = SourceLocation(fileID: file, line: line, column: column)
      var logger = logger
      if !payload.isEmpty {
        logger[metadataKey: "payload"] =
          "\(payload.map { "\($0 ?? "nil")" }.joined(separator: ", "))"
      }
      logger.info(
        "\(identifier) \(message)",
        source: codeLoc.description
      )
    }
  }

  public func warn(
    file: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ identifier: String = "⚠️",
    message: String,
    _ payload: Any?...
  ) {
    if isStarted, logThreshold <= .warn {
      let codeLoc = SourceLocation(fileID: file, line: line, column: column)
      var logger = logger
      if !payload.isEmpty {
        logger[metadataKey: "payload"] =
          "\(payload.map { "\($0 ?? "nil")" }.joined(separator: ", "))"
      }
      logger.warning(
        "\(identifier) \(message)",
        source: codeLoc.description
      )
    }
  }

  public func assertError(
    file: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ assert: @autoclosure () -> Bool,
    identifier: String = "⛔",
    message: String,
    _ payload: Any?...
  ) {
    if logThreshold <= .error, !assert() {
      error(
        file: file,
        line: line,
        column: column,
        identifier: identifier,
        message: message,
        payload
      )
    }
  }

  public func error(
    file: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    identifier: String = "⛔",
    message: String,
    _ payload: Any?...
  ) {
    if logThreshold <= .error {
      let codeLoc = SourceLocation(fileID: file, line: line, column: column)
      var logger = logger
      if !payload.isEmpty {
        logger[metadataKey: "payload"] =
          "\(payload.map { "\($0 ?? "nil")" }.joined(separator: ", "))"
      }
      logger.error(
        "\(identifier) \(message)",
        source: codeLoc.description
      )
      assertionFailure(
        """
        [\(identifier)] critical
        \t- \(message)
        \t- \(codeLoc.description)
        "\(payload.map { "\t- \($0 ?? "nil")" }.joined(separator: "\n"))"

        """
      )
    }
  }

  public func assertFatal(
    file: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ condition: @autoclosure () -> Bool = true,
    identifier: String = "💥",
    message: String,
    _ payload: Any?...
  ) {
    if logThreshold <= .critical, condition() {
      fatal(
        file: file,
        line: line,
        column: column,
        identifier: identifier,
        message: message,
        payload
      )
    }
  }

  public func fatal(
    file: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    identifier: String = "💥",
    message: String,
    _ payload: Any?...
  )
    -> Never
  {
    let codeLoc = SourceLocation(fileID: file, line: line, column: column)
    var logger = logger
    if !payload.isEmpty {
      logger[metadataKey: "payload"] = "\(payload.map { "\($0 ?? "nil")" }.joined(separator: ", "))"
    }
    logger.critical(
      "\(identifier) \(message)",
      source: codeLoc.description
    )
    fatalError(
      """
      [\(identifier)] critical
      \t- \(message)
      \t- \(codeLoc.description)
      "\(payload.map { "\t- \($0 ?? "nil")" }.joined(separator: "\n"))"

      """
    )
  }

  struct AlreadyStartedError: Error {}

  var isStarted = false

  private var logThreshold: LogLevel = .critical

  private let logger = Logger(label: "log.state-tree")

}
