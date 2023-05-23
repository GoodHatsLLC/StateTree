// MARK: - Union

public enum Union { }

// MARK: - UnionType

public protocol UnionType {
  var cardinality: Union.Cardinality { get }
  init?(payload: some Any, asCase: Union.Case)
  func caseMatches(_ other: Self) -> Bool
  var any: Any { get }
}

extension UnionType {
  public static func ~= (lhs: Self, rhs: Self) -> Bool {
    lhs.caseMatches(rhs)
  }
}

// MARK: - Union.Cardinality

extension Union {
  public enum Cardinality: Int {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
  }

  public enum Case {
    case a
    case b
    case c
    case d
  }
}

// MARK: - Union.One

extension Union {
  public enum One<A>: UnionType {
    case a(A)

    // MARK: Lifecycle

    public init?(payload: some Any, asCase unionCase: Union.Case) {
      if
        unionCase == .a,
        let a = payload as? A
      {
        self = .a(a)
      } else {
        return nil
      }
    }

    // MARK: Public

    public var cardinality: Union.Cardinality {
      .one
    }

    public var a: A? {
      value
    }

    public var value: A {
      switch self {
      case .a(let a): return a
      }
    }

    public var any: Any {
      switch self {
      case .a(let a): return a
      }
    }

    public func caseMatches(_: Union.One<A>) -> Bool {
      true
    }

  }
}

// MARK: - Union.Two

extension Union {
  public enum Two<A, B>: UnionType {
    case a(A)
    case b(B)

    // MARK: Lifecycle

    public init?(payload: some Any, asCase unionCase: Union.Case) {
      if unionCase == .a, let a = payload as? A {
        self = .a(a)
      } else if unionCase == .b, let b = payload as? B {
        self = .b(b)
      } else {
        return nil
      }
    }

    // MARK: Public

    public var cardinality: Union.Cardinality {
      .two
    }

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

    public var any: Any {
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

  }
}

// MARK: - Union.Three

extension Union {
  public enum Three<A, B, C>: UnionType {
    case a(A)
    case b(B)
    case c(C)

    // MARK: Lifecycle

    public init?(payload: some Any, asCase unionCase: Union.Case) {
      if unionCase == .a, let a = payload as? A {
        self = .a(a)
      } else if unionCase == .b, let b = payload as? B {
        self = .b(b)
      } else if unionCase == .c, let c = payload as? C {
        self = .c(c)
      } else {
        return nil
      }
    }

    // MARK: Public

    public var cardinality: Union.Cardinality {
      .three
    }

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

    public var any: Any {
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

  }
}

// MARK: - Union.Four

extension Union {
  public enum Four<A, B, C, D>: UnionType {
    case a(A)
    case b(B)
    case c(C)
    case d(D)

    // MARK: Lifecycle

    public init?(payload: some Any, asCase unionCase: Union.Case) {
      if unionCase == .a, let a = payload as? A {
        self = .a(a)
      } else if unionCase == .b, let b = payload as? B {
        self = .b(b)
      } else if unionCase == .c, let c = payload as? C {
        self = .c(c)
      } else if unionCase == .d, let d = payload as? D {
        self = .d(d)
      } else {
        return nil
      }
    }

    // MARK: Public

    public var cardinality: Union.Cardinality {
      .four
    }

    public var a: A? {
      switch self {
      case .b,
           .c,
           .d: return nil
      case .a(let a): return a
      }
    }

    public var b: B? {
      switch self {
      case .a,
           .c,
           .d: return nil
      case .b(let b): return b
      }
    }

    public var c: C? {
      switch self {
      case .a,
           .b,
           .d: return nil
      case .c(let c): return c
      }
    }

    public var d: D? {
      switch self {
      case .a,
           .b,
           .c: return nil
      case .d(let d): return d
      }
    }

    public var any: Any {
      switch self {
      case .a(let a): return a
      case .b(let b): return b
      case .c(let c): return c
      case .d(let d): return d
      }
    }

    public func caseMatches(_ other: Union.Four<A, B, C, D>) -> Bool {
      switch (self, other) {
      case (.a, .a): return true
      case (.b, .b): return true
      case (.c, .c): return true
      case (.d, .d): return true
      default: return false
      }
    }

  }
}
