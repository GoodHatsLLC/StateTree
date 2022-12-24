import Foundation
import Model
import SwiftUI
import Tree

@propertyWrapper
public struct StateTree<M: Model>: DynamicProperty {
  public init(wrappedValue: Tree<M>) {
    _value = .init(wrappedValue: wrappedValue.asObservable())
  }

  @StateObject private var value: ObservableTree<M>

  public var wrappedValue: Tree<M> {
    get { value.tree }
    nonmutating set { value.tree = newValue }
  }
}
