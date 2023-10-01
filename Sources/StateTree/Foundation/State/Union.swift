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
/// `U2` is a convenience alias for ``Union2``.
public typealias U2<A, B> = Union2<A, B>

// MARK: - Union2

/// `Union2` is a generic enum with two associated values types.
///
/// Construct it with ``a(_:)`` or ``b(_:)`` and access it with switch-case pattern matching
/// or with the ``a`` or``b`` accessors — which return the payload only if the access matches the
/// case.
public enum Union2<A, B>: UnionType {
  case a(A)
  case b(B)

  // MARK: Public

  /// Access the union's value if it is a ``a(_:)`` case.
  public var a: A? {
    switch self {
    case .a(let a): return a
    case .b: return nil
    }
  }

  /// Access the union's value if it is a ``b(_:)`` case.
  public var b: B? {
    switch self {
    case .b(let b): return b
    case .a: return nil
    }
  }

  @_spi(Implementation) public var anyPayload: Any {
    switch self {
    case .a(let a): return a
    case .b(let b): return b
    }
  }

  @_spi(Implementation)
  public func caseMatches(_ other: Union2<A, B>) -> Bool {
    switch (self, other) {
    case (.a, .a): return true
    case (.b, .b): return true
    default: return false
    }
  }

  @_spi(Implementation)
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

/// `U3` is a convenience alias for ``Union3``.
public typealias U3<A, B, C> = Union3<A, B, C>

// MARK: - Union3

/// `Union3` is a generic enum with three associated values types.
///
/// Construct it with ``a(_:)``, ``b(_:)``, or ``c(_:)`` and access it with switch-case pattern
/// matching
/// or with the ``a``, ``b``, or ``c`` accessors — which return the payload only if the access
/// matches the case.
public enum Union3<A, B, C>: UnionType {
  case a(A)
  case b(B)
  case c(C)

  // MARK: Public

  /// Access the union's value if it is a ``a(_:)`` case.
  public var a: A? {
    switch self {
    case .b,
         .c: return nil
    case .a(let a): return a
    }
  }

  /// Access the union's value if it is a ``b(_:)`` case.
  public var b: B? {
    switch self {
    case .a,
         .c: return nil
    case .b(let b): return b
    }
  }

  /// Access the union's value if it is a ``c(_:)`` case.
  public var c: C? {
    switch self {
    case .a,
         .b: return nil
    case .c(let c): return c
    }
  }

  @_spi(Implementation) public var anyPayload: Any {
    switch self {
    case .a(let a): return a
    case .b(let b): return b
    case .c(let c): return c
    }
  }

  @_spi(Implementation)
  public func caseMatches(_ other: Union3<A, B, C>) -> Bool {
    switch (self, other) {
    case (.a, .a): return true
    case (.b, .b): return true
    case (.c, .c): return true
    default: return false
    }
  }

  @_spi(Implementation)
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
