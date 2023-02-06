import Disposable
// MARK: - PreparedBehavior

public struct PreparedBehavior: Hashable {

  // MARK: Lifecycle

  init<Input>(_ behavior: some BehaviorType<Input>, input: Input) {
    self.id = behavior.id
    self.runOnScopeFunc = { scoping in
      behavior.run(on: scoping, input: input)
    }
    self.disposeFunc = {
      behavior.dispose()
    }
    self.resolutionFunc = {
      await behavior.resolution()
    }
  }

  // MARK: Public

  public let id: BehaviorID

  public static func == (lhs: PreparedBehavior, rhs: PreparedBehavior) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  // MARK: Internal

  func run(on scope: some Scoping) {
    runOnScopeFunc(scope)
  }

  func dispose() {
    disposeFunc()
  }

  func resolution() async -> BehaviorResolution {
    await resolutionFunc()
  }

  // MARK: Private

  private let runOnScopeFunc: (_ scoping: any Scoping) -> Void
  private let disposeFunc: () -> Void
  private let resolutionFunc: () async -> BehaviorResolution

}
