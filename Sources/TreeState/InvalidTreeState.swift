struct InvalidTreeState: Error {
  let expected: Any
  let runtime: Any?

  static func errorFor<T>(assumption _: T.Type) -> InvalidTreeState {
    InvalidTreeState(
      expected: T.self,
      runtime: nil
    )
  }

  static func errorFor<T>(assumption _: T.Type, state: AnyTreeState) -> InvalidTreeState {
    InvalidTreeState(
      expected: T.self,
      runtime: state._runtime.self as Any
    )
  }
}
