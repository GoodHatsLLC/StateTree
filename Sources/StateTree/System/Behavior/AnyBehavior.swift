// MARK: - AnyBehavior

public struct AnyBehavior<Input>: Hashable {

  // MARK: Lifecycle

  init(_ behavior: some BehaviorType<Input>) {
    self.id = behavior.id
    self.runFunc = { scoping, input in
      behavior.run(on: scoping, input: input)
    }
    self.disposeFunc = {
      behavior.dispose()
    }
    self.resolutionFunc = {
      await behavior.resolution()
    }
    self.underlying = behavior
  }

  // MARK: Public

  public let id: BehaviorID

  public static func == (lhs: AnyBehavior, rhs: AnyBehavior) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public func erase() -> Self {
    self
  }

  public func prepare(input: Input) -> PreparedBehavior {
    .init(underlying, input: input)
  }

  // MARK: Internal

  func run(on: some Scoping, input: Input) {
    runFunc(on, input)
  }

  func dispose() {
    disposeFunc()
  }

  func resolution() async -> BehaviorResolution {
    await resolutionFunc()
  }

  // MARK: Private

  private let underlying: any BehaviorType<Input>
  private let runFunc: (_ scoping: any Scoping, _ input: Input) -> Void
  private let disposeFunc: () -> Void
  private let resolutionFunc: () async -> BehaviorResolution

}
