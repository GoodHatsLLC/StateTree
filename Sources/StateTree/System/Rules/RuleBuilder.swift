
@resultBuilder
public enum RuleBuilder {

  public static func buildExpression(_: ()) -> EmptyRule {
    EmptyRule()
  }

  @_disfavoredOverload
  public static func buildExpression<R: Rules>(_ r: R) -> R {
    r
  }

  public static func buildExpression<R: Rules>(_ r: R?) -> some Rules {
    if let r {
      return EitherRule<R, EmptyRule>.ruleA(r)
    } else {
      return EitherRule<R, EmptyRule>.ruleB(.init())
    }
  }

  public static func buildExpression<R: Rules>(_ r: @autoclosure () throws -> R) -> some Rules {
    do {
      let rule = try r()
      return EitherRule<R, ErrorRule>.ruleA(rule)
    } catch {
      return EitherRule<R, ErrorRule>.ruleB(ErrorRule(error: error))
    }
  }

  public static func buildBlock<R: Rules>(_ rules: R) -> R {
    rules
  }

  public static func buildPartialBlock<R: Rules>(first: R) -> R {
    first
  }

  public static func buildPartialBlock(accumulated: some Rules, next: some Rules)
    -> some Rules
  {
    TupleRule(rule1: accumulated, rule2: next)
  }

  public static func buildOptional(_ component: (some Rules)?) -> some Rules {
    MaybeRule(optionalRules: component)
  }

  public static func buildEither<RA: Rules, RB: Rules>(first: RA) -> EitherRule<RA, RB> {
    EitherRule<RA, RB>.ruleA(first)
  }

  public static func buildEither<RA: Rules, RB: Rules>(second: RB) -> EitherRule<RA, RB> {
    EitherRule<RA, RB>.ruleB(second)
  }

}
