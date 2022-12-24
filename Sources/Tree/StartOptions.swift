import Dependencies
import Utilities

// MARK: - StartOption

public enum StartOption {
  case statePlayback(mode: StatePlaybackMode)
  case logging(threshold: LogLevel)
  case dependencies(DependencyValues)
}

// MARK: - StatePlaybackMode

public enum StatePlaybackMode {
  case playback(any TreeStatePlayer)
  case record(any TreeStateRecord)
}
