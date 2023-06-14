#if DEBUG && canImport(os)
import os

public let rw = (
  dso: { () -> UnsafeMutableRawPointer in
    let count = _dyld_image_count()
    for i in 0 ..< count {
      if let name = _dyld_get_image_name(i) {
        let swiftString = String(cString: name)
        if swiftString.hasSuffix("/SwiftUI") {
          if let header = _dyld_get_image_header(i) {
            return UnsafeMutableRawPointer(mutating: UnsafeRawPointer(header))
          }
        }
      }
    }
    return UnsafeMutableRawPointer(mutating: #dsohandle)
  }(),
  log: OSLog(subsystem: "com.apple.runtime-issues", category: "StateTree")
)
#endif

@_transparent
@inline(__always)
public func runtimeWarning(
  _ message: @autoclosure () -> StaticString,
  _ args: @autoclosure () -> [any CVarArg] = []
) {
  #if DEBUG && canImport(os)
  let message = message()
  unsafeBitCast(
    os_log as (OSLogType, UnsafeRawPointer, OSLog, StaticString, (any CVarArg)...) -> Void,
    to: ((OSLogType, UnsafeRawPointer, OSLog, StaticString, [any CVarArg]) -> Void).self
  )(.fault, rw.dso, rw.log, message, args())
  #endif
}
