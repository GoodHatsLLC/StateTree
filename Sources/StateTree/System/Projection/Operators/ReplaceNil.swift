extension Projection {

  public func replaceNil<Downstream>(default defaultValue: Downstream) -> Projection<Downstream>
    where Value == Downstream?
  {
    map { upstream in
      upstream ?? defaultValue
    } upwards: { varUpstream, downstream in
      varUpstream = downstream
    }
  }

}
