import Disposable
import Foundation

public enum Uptime {

  public static var systemUptime: TimeInterval {
    #if DEBUG
      debugUptime() ?? prodUptime()
    #else
      prodUptime()
    #endif
  }

  #if DEBUG
    private static var nextUptime: TimeInterval?
    private static func debugUptime() -> TimeInterval? {
      defer { Self.nextUptime = Self.nextUptime.map { $0 + 1 } }
      return Self.nextUptime
    }

    @MainActor
    public static func debug_overrideUptime(incrementingFrom value: TimeInterval = 0)
      -> AnyDisposable
    {
      nextUptime = value
      return AnyDisposable { nextUptime = nil }
    }
  #endif

  private static func prodUptime() -> TimeInterval {
    ProcessInfo.processInfo.systemUptime
  }

}
