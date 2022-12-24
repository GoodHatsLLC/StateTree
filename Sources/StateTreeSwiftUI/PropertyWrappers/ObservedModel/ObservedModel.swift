import Combine
import Disposable
import Emitter
import Foundation
import Model
import SwiftUI

// MARK: - ObservedModel

@MainActor
@propertyWrapper
public struct ObservedModel<M: Model>: DynamicProperty {

  public init(wrappedValue: M) {
    observed = ObservableModel(model: wrappedValue)
  }

  public var wrappedValue: M {
    get { observed.model }
    nonmutating set {
      observed.model = newValue
    }
  }

  public var projectedValue: Binding<M> {
    observed.model.projection.binding()
  }

  @ObservedObject var observed: ObservableModel<M>
}
