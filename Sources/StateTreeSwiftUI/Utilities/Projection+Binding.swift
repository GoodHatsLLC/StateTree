import StateTree
import SwiftUI

extension Projection {

  // MARK: Lifecycle

  public init(_ binding: Binding<Value>) {
    self = .captured(
      getter: { binding.wrappedValue },
      setter: { binding.wrappedValue = $0 }
    )
  }

  // MARK: Public

  public func binding() -> Binding<Value> {
    Binding {
      self.wrappedValue
    } set: { newValue in
      self.wrappedValue = newValue
    }
  }

}
