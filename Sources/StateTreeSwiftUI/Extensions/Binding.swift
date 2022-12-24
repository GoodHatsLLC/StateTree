import Foundation
import Projection
import SwiftUI

extension Binding {

  public func compact<V>() -> Binding<V>?
  where Value == V? {
    Binding<V>(self)
  }

  public func replaceNil<Downstream>(default defaultValue: Downstream) -> Binding<Downstream>
  where Value == Downstream? {
    Binding<Downstream> {
      wrappedValue ?? defaultValue
    } set: { newValue in
      wrappedValue = newValue
    }
  }

}
