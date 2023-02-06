#if CUSTOM_ACTOR
@globalActor
public actor CustomActor: GlobalActor {
  public typealias ActorType = CustomActor

  public static let shared: CustomActor = .init()
}

public typealias TreeActor = CustomActor
#else
public typealias TreeActor = MainActor
#endif

extension TreeActor {

  public enum TreeActorType {
    case custom
    case main
  }

  public static var type: TreeActorType {
    #if CUSTOM_ACTOR
      .custom
    #else
      .main
    #endif
  }

}
