
// MARK: - NodeRecord

/// The underlying representation of a ``Node`` managed by StateTree.
///
/// The `NodeRecord` includes all of the node's StateTree managed fields.
/// (Fields are managed by StateTree when annotated with property wrappers like ``Value`` and
/// ``Projection``.
struct NodeRecord: TreeState {
  var id: NodeID
  let origin: RouteSource
  var records: [FieldRecord]
}
