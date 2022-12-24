import Foundation

// MARK: - RouteBuilder

@resultBuilder
public enum RouteBuilder {

  public static func buildBlock() -> some Routing {
    VoidRoute()
  }

  public static func buildExpression(_: ()) -> some Routing {
    VoidRoute()
  }

  public static func buildBlock<T: Model>(_ one: T) -> T {
    one
  }

  public static func buildExpression<R: Routing>(_ one: R) -> R {
    one
  }

  public static func buildBlock<R: Routing>(_ one: R) -> R {
    one
  }

  public static func buildPartialBlock(first: some Routing) -> some Routing {
    first
  }

  public static func buildPartialBlock(accumulated: some Routing, next: some Routing)
    -> some Routing
  {
    TupleRoute(route1: accumulated, route2: next)
  }

  public static func buildOptional(_ component: (some Routing)?) -> some Routing {
    MaybeRoute(optionalRoutes: component)
  }

  public static func buildEither<RA: Routing, RB: Routing>(first: RA) -> EitherRoute<RA, RB> {
    EitherRoute<RA, RB>.routesA(first)
  }

  public static func buildEither<RA: Routing, RB: Routing>(second: RB) -> EitherRoute<RA, RB> {
    EitherRoute<RA, RB>.routesB(second)
  }

}
