extension Task {
  @MainActor
  public func resultBehavior(
    fileID _: String = #fileID,
    line _: Int = #line,
    column _: Int = #column,
    id: String? = nil
  ) -> Behavior<Success> {
    Behavior(id) {
      try await self.value
    }
  }
}
