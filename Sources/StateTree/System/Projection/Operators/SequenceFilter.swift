import TreeState

extension Projection
  where
  Value: MutableCollection, Value: RangeReplaceableCollection,
  Value.Element: Identifiable, Value.Element: TreeState
{
  func filter(
    isIncluded: @escaping (Value.Element) -> Bool
  ) -> Projection<[Value.Element]> {
    map(
      downwards: { upstream in
        upstream.filter(isIncluded)
      },
      upwards: { varUpstream, downstream in
        let upstreamCandidates = varUpstream.filter(isIncluded)
        let upstreamSet = Set(upstreamCandidates.map(\.id))
        let downstreamSet = Set(downstream.map(\.id))

        let deletions = upstreamSet.subtracting(downstreamSet)
        let additions = downstreamSet.subtracting(upstreamSet)
        let updates = upstreamSet.intersection(downstreamSet)

        let index = downstream.reduce(into: [AnyHashable: Value.Element]()) { acc, curr in
          acc[curr.id] = curr
        }

        var new = varUpstream.filter { !deletions.contains($0.id) }
        for i in new.indices where updates.contains(new[i].id) {
          if let update = index[new[i].id] {
            new[i] = update
          }
        }
        new += additions.compactMap { index[$0] }
        varUpstream = new
      },
      isValid: { _ in
        true
      }
    )
  }
}
