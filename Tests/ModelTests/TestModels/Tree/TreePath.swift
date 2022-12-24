import Model

// MARK: - TreeSegmentModel

protocol TreeSegmentModel: ModelState {
  func asSegment() -> TreePath.Segment
  var segmentType: TreePath.SegmentType { get }
  var trunkPath: TreePath.Trunk? { get }
  var boughTaperPath: TreePath.Bough? { get }
  var boughBranchPath: (lhs: TreePath.Bough, rhs: TreePath.Bough)? { get }
  var boughPath: TreePath.Bough? { get }
  var twigTaperPath: TreePath.Twig? { get }
  var twigBranchPath: (lhs: TreePath.Twig, rhs: TreePath.Twig)? { get }
  var twigPath: TreePath.Twig? { get }
  var leafPath: TreePath.Leaf? { get }
}

extension TreeSegmentModel {
  var trunkPath: TreePath.Trunk? { nil }
  var boughTaperPath: TreePath.Bough? { nil }
  var boughBranchPath: (lhs: TreePath.Bough, rhs: TreePath.Bough)? { nil }
  var boughPath: TreePath.Bough? { nil }
  var twigTaperPath: TreePath.Twig? { nil }
  var twigBranchPath: (lhs: TreePath.Twig, rhs: TreePath.Twig)? { nil }
  var twigPath: TreePath.Twig? { nil }
  var leafPath: TreePath.Leaf? { nil }
}

// MARK: - TreePath

enum TreePath {
  enum SegmentType: String {
    case root
    case trunk
    case bough
    case twig
    case leaf
  }

  enum Segment: TreeSegmentModel {
    case root(Root)
    case trunk(Trunk)
    case bough(Bough)
    case twig(Twig)
    case leaf(Leaf)

    var segmentType: TreePath.SegmentType { segment.segmentType }
    var trunkPath: TreePath.Trunk? { segment.trunkPath }
    var boughTaperPath: TreePath.Bough? { segment.boughTaperPath }
    var boughBranchPath: (lhs: TreePath.Bough, rhs: TreePath.Bough)? { segment.boughBranchPath }
    var boughPath: TreePath.Bough? { segment.boughPath }
    var twigTaperPath: TreePath.Twig? { segment.twigTaperPath }
    var twigBranchPath: (lhs: TreePath.Twig, rhs: TreePath.Twig)? { segment.twigBranchPath }
    var twigPath: TreePath.Twig? { segment.twigPath }
    var leafPath: TreePath.Leaf? { segment.leafPath }

    var lhs: TreePath.Segment? {
      if let trunkPath {
        return trunkPath.asSegment()
      } else if let boughTaperPath {
        return boughTaperPath.asSegment()
      } else if let boughBranchPath {
        return boughBranchPath.lhs.asSegment()
      } else if let boughPath {
        return boughPath.asSegment()
      } else if let twigTaperPath {
        return twigTaperPath.asSegment()
      } else if let twigBranchPath {
        return twigBranchPath.lhs.asSegment()
      } else if let twigPath {
        return twigPath.asSegment()
      } else if let leafPath {
        return leafPath.asSegment()
      }
      return nil
    }

    var rhs: TreePath.Segment? {
      if let boughBranchPath {
        return boughBranchPath.rhs.asSegment()
      } else if let twigBranchPath {
        return twigBranchPath.rhs.asSegment()
      }
      return nil
    }

    func asSegment() -> TreePath.Segment { self }

    private var segment: any TreeSegmentModel {
      switch self {
      case .root(let value): return value
      case .trunk(let value): return value
      case .bough(let value): return value
      case .twig(let value): return value
      case .leaf(let value): return value
      }
    }

  }

  enum Root: TreeSegmentModel {
    // Cases
    case trunk(Trunk)
    // Optional Accessors
    var trunkPath: Trunk? {
      switch self {
      case .trunk(let trunk): return trunk
      }
    }

    func asSegment() -> TreePath.Segment { .root(self) }
    var segmentType: TreePath.SegmentType { .root }
  }

  indirect enum Trunk: TreeSegmentModel {
    // Cases
    case trunk(Trunk)
    case taper(Bough)
    case branch(Bough, Bough)

    // Optional Accessors
    var trunkPath: Trunk? {
      switch self {
      case .trunk(let trunk): return trunk
      case .taper: return nil
      case .branch: return nil
      }
    }

    var boughTaperPath: Bough? {
      switch self {
      case .trunk: return nil
      case .taper(let bough): return bough
      case .branch: return nil
      }
    }

    var boughBranchPath: (lhs: Bough, rhs: Bough)? {
      switch self {
      case .trunk: return nil
      case .taper: return nil
      case .branch(let lhs, let rhs): return (lhs, rhs)
      }
    }

    var segmentType: TreePath.SegmentType { .trunk }

    func asSegment() -> TreePath.Segment { .trunk(self) }
  }

  indirect enum Bough: TreeSegmentModel {
    // Cases
    case branch(Bough, Bough)
    case bough(Bough)
    case taper(Twig)

    // Optional Accessors
    var boughBranchPath: (lhs: Bough, rhs: Bough)? {
      switch self {
      case .branch(let lhs, let rhs): return (lhs, rhs)
      case .bough: return nil
      case .taper: return nil
      }
    }

    var boughPath: Bough? {
      switch self {
      case .branch: return nil
      case .bough(let bough): return bough
      case .taper: return nil
      }
    }

    var twigTaperPath: Twig? {
      switch self {
      case .branch: return nil
      case .bough: return nil
      case .taper(let twig): return twig
      }
    }

    var segmentType: TreePath.SegmentType { .bough }

    func asSegment() -> TreePath.Segment { .bough(self) }
  }

  indirect enum Twig: TreeSegmentModel {
    // Cases
    case branch(Twig, Twig)
    case twig(Twig)
    case leaf(Leaf)

    // Optional Accessors
    var twigBranchPath: (lhs: Twig, rhs: Twig)? {
      switch self {
      case .branch(let lhs, let rhs): return (lhs, rhs)
      case .twig: return nil
      case .leaf: return nil
      }
    }

    var twigPath: Twig? {
      switch self {
      case .branch: return nil
      case .twig(let twig): return twig
      case .leaf: return nil
      }
    }

    var leafPath: Leaf? {
      switch self {
      case .branch: return nil
      case .twig: return nil
      case .leaf(let leaf): return leaf
      }
    }

    var segmentType: TreePath.SegmentType { .twig }

    func asSegment() -> TreePath.Segment { .twig(self) }
  }

  struct Leaf: TreeSegmentModel {
    func asSegment() -> TreePath.Segment { .leaf(self) }
    var segmentType: TreePath.SegmentType { .leaf }
  }
}
