import Emitter
import TreeActor
import Utilities

// MARK: - Sync

extension Behaviors {

  /// Make a `SyncSingle<Input, Output, Never>` behavior.
  ///
  /// Create a non-erroring `Output` emitting, synchronous, behavior taking an `Input` type value.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped
  /// out in tests.
  /// - Parameter input: `Input.self` — the `Input` type the created `Behavior` will require.
  /// - Parameter subscribe: the action run to subscribe the `Behavior` to the `Input`,  to run
  /// any of the Behavior's side effects and to create its `Output` value.
  /// - Returns: A ``Behaviors/Behaviors/SyncSingle`` taking an `Input` type value and synchronously
  /// emitting an `Output` value.
  ///
  /// > Tip: The behavior is not executed and can be passed to other consumers.
  @TreeActor
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    input _: Input.Type,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping Make<Input, Output>.SyncFunc.NonThrowing
  ) -> SyncSingle<Input, Output, Never> {
    .init(
      id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "sync-single"),
      subscribeFunc: subscribe
    )
  }

  /// Make a `SyncSingle<Input, Output, any Error>` behavior.
  ///
  /// Create an `Output` emitting, synchronous, behavior taking an `Input` type value, and
  /// potentially throwing `any Error`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped
  /// out in tests.
  /// - Parameter input: `Input.self` — the `Input` type the created `Behavior` will require.
  /// - Parameter subscribe: the action run to subscribe the `Behavior` to the `Input`,  to run
  /// any of the Behavior's side effects and to create its `Output` value.
  /// - Returns: A ``Behaviors/Behaviors/SyncSingle`` taking an `Input` type value and synchronously
  /// emitting an `Output` value, or failing with an `any Error`.
  ///
  /// > Tip: The behavior is not executed and can be passed to other consumers.
  @TreeActor
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    input _: Input.Type,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping Make<Input, Output>.SyncFunc.Throwing
  ) -> SyncSingle<Input, Output, any Error> {
    .init(
      id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "sync-single-throws"),
      subscribeFunc: subscribe
    )
  }
}

// MARK: - Async

extension Behaviors {

  /// Make an `AsyncSingle<Input, Output, Never>` behavior.
  ///
  /// Create a non-erroring `Output` emitting, asynchronous, behavior taking an `Input` type value.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped
  /// out in tests.
  /// - Parameter input: `Input.self` — the `Input` type the created `Behavior` will require.
  /// - Parameter subscribe: the action run to subscribe the `Behavior` to the `Input`,  to run
  /// any of the Behavior's side effects and to create its `Output` value.
  /// - Returns: A ``Behaviors/Behaviors/AsyncSingle`` taking an `Input` type value and
  /// asynchronously emitting an `Output` value.
  ///
  /// > Tip: The behavior is not executed and can be passed to other consumers.
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    input _: Input.Type,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping Make<Input, Output>.AsyncFunc.NonThrowing
  ) -> AsyncSingle<Input, Output, Never> {
    .init(
      id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "async-single"),
      subscribeFunc: subscribe
    )
  }

  /// Make an `AsyncSingle<Input, Output, Never>` behavior.
  ///
  /// Create a `Output` emitting, asynchronous, behavior taking an `Input` type value, and
  /// potentially throwing `any Error`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped
  /// out in tests.
  /// - Parameter input: `Input.self` — the `Input` type the created `Behavior` will require.
  /// - Parameter subscribe: the action run to subscribe the `Behavior` to the `Input`,  to run
  /// any of the Behavior's side effects and to create its `Output` value.
  /// - Returns: A ``Behaviors/Behaviors/AsyncSingle`` taking an `Input` type value and
  /// asynchronously emitting an `Output` value, or failing with an `any Error`.
  ///
  /// > Tip: The behavior is not executed and can be passed to other consumers.
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    input _: Input.Type,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping Make<Input, Output>.AsyncFunc.Throwing
  ) -> AsyncSingle<Input, Output, any Error> {
    .init(
      id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "async-single-throws"),
      subscribeFunc: subscribe
    )
  }
}

// MARK: - Stream

extension Behaviors {

  /// Make a `Stream<Input, Output>` behavior asynchronously.
  ///
  /// Create a ``Behavior`` taking an `Input` type value, emitting a stream of `Output`
  /// values,
  /// and potentially terminating with `any Error` — from an asynchronous closure returning an
  /// `AsyncSequence`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped
  /// out in tests.
  /// - Parameter input: `Input.self` — the `Input` type the created `Behavior` will require.
  /// - Parameter subscribe: the action run to subscribe the `Behavior` to the `Input` and to run
  /// any of the Behavior's side effects and to emit its `Output` values.
  /// - Returns: A ``Behaviors/Behaviors/Stream`` taking an `Input` type value, emitting any number
  /// of `Output` values before finishing successfully or failing with `any Error`.
  ///
  /// > Tip: The behavior is not executed and can be passed to other consumers.
  public static func make<Input, Seq: AsyncSequence>(
    _ id: BehaviorID? = nil,
    input _: Input.Type,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping Make<Input, Seq.Element>.StreamFunc.Concrete<Seq>
  ) -> Stream<Input, Seq.Element, Error> {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: "stream-asyncfunc"
    )
    return .init(id, subscribeFunc: subscribe)
  }

  /// **Convenience:* Make a `Stream<Input, Output>` behavior from an `Emitter`.
  ///
  /// Create a ``Behavior`` taking an `Input` type value, emitting a stream of `Output`
  /// values,
  /// and potentially terminating with `any Error` — from an asynchronous closure returning a
  /// `Publisher`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped
  /// out in tests.
  /// - Parameter input: `Input.self` — the `Input` type the created `Behavior` will require.
  /// - Parameter subscribe: the action run to subscribe the `Behavior` to the `Input`,  to run
  /// any of the Behavior's side effects and to emit its `Output` values.
  /// - Returns: A ``Behaviors/Behaviors/Stream`` taking an `Input` type value, emitting any number
  /// of `Output` values before finishing successfully or failing with `any Error`.
  ///
  /// > Tip: The `Behavior` is not executed and can be passed to other consumers.
  @_spi(Implementation)
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    input: Input.Type,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) async -> some Emitter<Output, Never>
  ) -> Stream<Input, Output, Error> {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: "stream-emitter-asyncfunc"
    )
    return make(id, input: input) {
      await subscribe($0).values
    }
  }

  /// *Convenience:* Make a `Stream<Input, Output>` behavior from a `Combine` `Publisher`.
  ///
  /// Create a ``Behavior`` taking an `Input` type value, emitting a stream of `Output`
  /// values,
  /// and potentially terminating with `any Error` — from an asynchronous closure returning a
  /// `Publisher`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped
  /// out in tests.
  /// - Parameter input: `Input.self` — the `Input` type the created `Behavior` will require.
  /// - Parameter subscribe: the action run to subscribe the `Behavior` to the `Input`,  to run
  /// any of the Behavior's side effects and to emit its `Output` values.
  /// - Returns: A ``Behaviors/Behaviors/Stream`` taking an `Input` type value, emitting any number
  /// of `Output` values before finishing successfully or failing with `any Error`.
  ///
  /// > Tip: The `Behavior` is not executed and can be passed to other consumers.
  @_spi(Implementation)
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    input: Input.Type,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) -> some Emitter<Output, Never>
  ) -> Stream<Input, Output, Error> {
    let id = id ?? .meta(moduleFile: moduleFile, line: line, column: column, meta: "stream-emitter")
    return make(id, input: input) {
      subscribe($0).values
    }
  }

}

#if canImport(Combine)
import Combine
extension Behaviors {
  /// *Convenience:* Make a `Stream<Input, Output>` behavior from a `Combine` `Publisher`.
  ///
  /// Create a ``Behavior`` taking an `Input` type value, emitting a stream of `Output`
  /// values,
  /// and potentially terminating with `any Error` — from an asynchronous closure returning a
  /// `Combine` `Publisher`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped
  /// out in tests.
  /// - Parameter input: `Input.self` — the `Input` type the created `Behavior` will require.
  /// - Parameter subscribe: the action run to subscribe the `Behavior` to the `Input`,  to run
  /// any of the Behavior's side effects and to emit its `Output` values.
  /// - Returns: A ``Behaviors/Behaviors/Stream`` taking an `Input` type value, emitting any number
  /// of `Output` values before finishing successfully or failing with `any Error`.
  ///
  /// > Tip: The `Behavior` is not executed and can be passed to other consumers.
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    input: Input.Type,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) async -> some Publisher<Output, Never>
  ) -> Stream<Input, Output, Error> {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: "stream-publisher-asyncfunc"
    )
    return make(id, input: input) {
      await Async.Combine.bridge(publisher: subscribe($0))
    }
  }

  /// *Convenience:* Make a `Stream<Input, Output>` behavior from a `Publisher`.
  ///
  /// Create a ``Behavior`` taking an `Input` type value, emitting a stream of `Output`
  /// values,
  /// and potentially terminating with `any Error` — from a synchronous closure returning a
  /// `Publisher`.
  ///
  /// - Parameter id: the ``BehaviorID`` representing the created Behavior — with which it can be
  /// swapped
  /// out in tests.
  /// - Parameter input: `Input.self` — the `Input` type the created `Behavior` will require.
  /// - Parameter subscribe: the action run to subscribe the `Behavior` to the `Input`,  to run
  /// any of the Behavior's side effects and to emit its `Output` values.
  /// - Returns: A ``Behaviors/Behaviors/Stream`` taking an `Input` type value, emitting any number
  /// of `Output` values before finishing successfully or failing with `any Error`.
  ///
  /// > Tip: The behavior is not executed and can be passed to other consumers.
  public static func make<Input, Output>(
    _ id: BehaviorID? = nil,
    input: Input.Type,
    moduleFile: String = #file,
    line: Int = #line,
    column: Int = #column,
    subscribe: @escaping (_ input: Input) -> some Publisher<Output, some Error>
  ) -> Stream<Input, Output, Error> {
    let id = id ?? .meta(
      moduleFile: moduleFile,
      line: line,
      column: column,
      meta: "stream-publisher"
    )
    return make(id, input: input) {
      Async.Combine.bridge(publisher: subscribe($0))
    }
  }
}

#endif
