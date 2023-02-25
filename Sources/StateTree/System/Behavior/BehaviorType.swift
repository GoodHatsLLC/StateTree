import Disposable

// MARK: - Behavior

public protocol Behavior<Input>: Sendable {
  associatedtype Input: Sendable
  associatedtype Action
  associatedtype Output: Sendable
  associatedtype Handler: BehaviorHandler where Handler.Output == Output
  init(id: BehaviorID, _: Action)
  var id: BehaviorID { get }
  func erase() -> AnyBehavior<Input>
  func prepare(_ input: Input) -> PreparedBehavior
  func subscribe(handler: Handler)
}

extension Behavior where Input == Void {
  func prepare() -> PreparedBehavior {
    prepare(())
  }
}

// MARK: - BehaviorHandler

public protocol BehaviorHandler<Output, Failure> {
  associatedtype Output
  associatedtype Failure: Error
}

// MARK: - Never + BehaviorHandler

extension Never: BehaviorHandler {
  public typealias Failure = Never
  public typealias Output = Void
}

// MARK: - BehaviorType

public protocol BehaviorType<Input>: Behavior, Sendable {
  /// Run the Behavior binding its lifetime to the passed scope.
  ///
  /// The Behavior is cancelled if the scope deactivates before it finishes.
  func run(on scope: some Scoping, input: Input)
  func resolution() async -> BehaviorResolution
  func dispose()
  var action: Action { get }
}

extension BehaviorType {

  public func erase() -> AnyBehavior<Input> {
    .init(self)
  }

  public func prepare(_ input: Input) -> PreparedBehavior {
    .init(self, input: input)
  }
}

extension Behavior {

  @TreeActor
  public static func owning<I>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ disposable: @escaping (I) -> some Disposable
  )
    -> OwningBehavior<I> where Self == OwningBehavior<I>
  {
    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
    return OwningBehavior(id: id, disposable)
  }

  @TreeActor
  public static func sequence<I, T, S: AsyncSequence>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ sequenceAction: @escaping @Sendable (I) -> S
  ) -> AsyncSequenceBehavior<I, T>
    where S.Element == T, Self == AsyncSequenceBehavior<I, T>
  {
    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
    return AsyncSequenceBehavior(id: id) { AnyAsyncSequence<T>(sequenceAction($0)) }
  }

  @TreeActor
  public static func value<I, T>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ action: @escaping @Sendable @TreeActor (I) -> T
  ) -> ValueBehavior<I, T>
    where Self == ValueBehavior<I, T>
  {
    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
    return ValueBehavior(id: id, action)
  }

  @TreeActor
  public static func always<I, T>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ action: @escaping @Sendable (I) async -> T
  ) -> AsyncValueBehavior<I, T>
    where Self == AsyncValueBehavior<I, T>
  {
    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
    return AsyncValueBehavior(id: id, action)
  }

  @TreeActor
  public static func throwing<I, T>(
    fileID: String = #fileID,
    line: Int = #line,
    column: Int = #column,
    _ id: BehaviorID? = nil,
    _ action: @escaping @Sendable (I) async throws -> T
  ) -> AsyncThrowingBehavior<I, T>
    where Self == AsyncThrowingBehavior<I, T>
  {
    let id = id ?? .init(fileID: fileID, line: line, column: column, custom: nil)
    return AsyncThrowingBehavior(id: id, action)
  }
}
