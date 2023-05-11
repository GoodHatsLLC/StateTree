
extension Projection
  where
  Value: MutableCollection, Value: RangeReplaceableCollection,
  Value.Element: Identifiable, Value.Element: Equatable
{
  func first(
    where isIncluded: @escaping (Value.Element) -> Bool
  ) -> Projection<Value.Element?> {
    map(
      downwards: { upstream in
        upstream.first(where: isIncluded)
      },
      upwards: { varUpstream, downstream in
        if
          let downstream,
          let index =
          varUpstream
            .firstIndex(where: isIncluded)
        {
          varUpstream[index] = downstream
        }
      },
      isValid: { upstream in
        upstream.contains(where: isIncluded)
      }
    )
  }
}
