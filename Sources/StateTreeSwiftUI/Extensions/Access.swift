import Foundation
import Projection
import SwiftUI

extension Binding {
  @MainActor
  public init(_ projection: some Accessor<Value>) {
    self = projection.binding()
  }
}

extension Accessor {

  public func binding() -> Binding<Value> {
    .init {
      value
    } set: { newValue in
      value = newValue
    }
  }
}
