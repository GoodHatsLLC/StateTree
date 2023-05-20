public enum Union { }

extension Union {

  public enum Two<A, B> {
    case a(A)
    case b(B)


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
    public init?(payload: some Any) {
      if let a = payload as? A {
        self = .a(a)
      } else if let b = payload as? B {
        self = .b(b)
      } else {
        return nil
      }
    }
  }

  public enum Three<A, B, C> {
    case a(A)
    case b(B)
    case c(C)


    public var a: A? {
      switch self {
      case .b, .c: return nil
      case .a(let a): return a
      }
    }

    public var b: B? {
      switch self {
      case .a, .c: return nil
      case .b(let b): return b
      }
    }

    public var c: C? {
      switch self {
      case .a, .b: return nil
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
    public init?(payload: some Any) {
      if let a = payload as? A {
        self = .a(a)
      } else if let b = payload as? B {
        self = .b(b)
      } else if let c = payload as? C {
        self = .c(c)
      } else {
        return nil
      }
    }
  }
}
