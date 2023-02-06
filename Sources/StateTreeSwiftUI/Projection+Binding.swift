#if !CUSTOM_ACTOR
import StateTree
import SwiftUI

extension Projection {
  public func binding() -> Binding<Value> {
    Binding {
      self.wrappedValue
    } set: { newValue in
      self.wrappedValue = newValue
    }
  }
}

extension Binding {
  public func compact<T>() -> Binding<T>? where Value == T? {
    Binding<T>(self)
  }
}
#endif
