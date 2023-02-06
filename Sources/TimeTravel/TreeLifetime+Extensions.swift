import StateTree

extension TreeLifetime {
  public func recorder(frames: [StateFrame] = []) -> Recorder<N> {
    Recorder(lifetime: self, frames: frames)
  }

  public func player(frames: [StateFrame]) throws -> Player<N> {
    try Player(lifetime: self, frames: frames)
  }
}
