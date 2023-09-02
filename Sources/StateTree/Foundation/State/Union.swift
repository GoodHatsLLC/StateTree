// MARK: - UnionType

public protocol UnionType {
  func caseMatches(_ other: Self) -> Bool
  var anyPayload: Any { get }
}

extension UnionType {
  public static func ~= (lhs: Self, rhs: Self) -> Bool {
    lhs.caseMatches(rhs)
  }
}

// MARK: - Union2

public enum Union2<A, B>: UnionType {
  case a(A)
  case b(B)

  // MARK: Public

  public var a: A? {
    switch self {
    case .a(let a): return a
    case .b: return nil
    }
  }

  public var b: B? {
    switch self {
    case .b(let b): return b
    case .a: return nil
    }
  }

  public var anyPayload: Any {
    switch self {
    case .a(let a): return a
    case .b(let b): return b
    }
  }

  public func caseMatches(_ other: Union2<A, B>) -> Bool {
    switch (self, other) {
    case (.a, .a): return true
    case (.b, .b): return true
    default: return false
    }
  }

  public func map<NewA, NewB>(
    a aMap: (A) -> NewA,
    b bMap: (B) -> NewB
  ) -> Union2<NewA, NewB> {
    switch self {
    case .a(let a): return Union2<NewA, NewB>.a(aMap(a))
    case .b(let b): return Union2<NewA, NewB>.b(bMap(b))
    }
  }
}

// MARK: - Union3

public enum Union3<A, B, C>: UnionType {
  case a(A)
  case b(B)
  case c(C)

  // MARK: Public

  public var a: A? {
    switch self {
    case .b,
         .c: return nil
    case .a(let a): return a
    }
  }

  public var b: B? {
    switch self {
    case .a,
         .c: return nil
    case .b(let b): return b
    }
  }

  public var c: C? {
    switch self {
    case .a,
         .b: return nil
    case .c(let c): return c
    }
  }

  public var anyPayload: Any {
    switch self {
    case .a(let a): return a
    case .b(let b): return b
    case .c(let c): return c
    }
  }

  public func caseMatches(_ other: Union3<A, B, C>) -> Bool {
    switch (self, other) {
    case (.a, .a): return true
    case (.b, .b): return true
    case (.c, .c): return true
    default: return false
    }
  }

  public func map<NewA, NewB, NewC>(
    a aMap: (A) -> NewA,
    b bMap: (B) -> NewB,
    c cMap: (C) -> NewC
  ) -> Union3<NewA, NewB, NewC> {
    switch self {
    case .a(let a): return Union3<NewA, NewB, NewC>.a(aMap(a))
    case .b(let b): return Union3<NewA, NewB, NewC>.b(bMap(b))
    case .c(let c): return Union3<NewA, NewB, NewC>.c(cMap(c))
    }
  }

}
