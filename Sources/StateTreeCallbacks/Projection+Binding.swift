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
