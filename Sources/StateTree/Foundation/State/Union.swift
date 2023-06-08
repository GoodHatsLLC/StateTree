// MARK: - Union

public enum Union { }

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

// MARK: - Union.Two

extension Union {
  public enum Two<A, B>: UnionType {
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

    public func caseMatches(_ other: Union.Two<A, B>) -> Bool {
      switch (self, other) {
      case (.a, .a): return true
      case (.b, .b): return true
      default: return false
      }
    }

    public func map<NewA, NewB>(
      a aMap: (A) -> NewA,
      b bMap: (B) -> NewB
    ) -> Union.Two<NewA, NewB> {
      switch self {
      case .a(let a): return Union.Two<NewA, NewB>.a(aMap(a))
      case .b(let b): return Union.Two<NewA, NewB>.b(bMap(b))
      }
    }
  }
}

// MARK: - Union.Three

extension Union {
  public enum Three<A, B, C>: UnionType {
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

    public func caseMatches(_ other: Union.Three<A, B, C>) -> Bool {
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
    ) -> Union.Three<NewA, NewB, NewC> {
      switch self {
      case .a(let a): return Union.Three<NewA, NewB, NewC>.a(aMap(a))
      case .b(let b): return Union.Three<NewA, NewB, NewC>.b(bMap(b))
      case .c(let c): return Union.Three<NewA, NewB, NewC>.c(cMap(c))
      }
    }

  }
}
