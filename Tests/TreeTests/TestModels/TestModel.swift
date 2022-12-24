import Emitter
import Foundation
import Model
import Node
import Projection

// MARK: - TestModel

struct TestModel: Model {

  init(store: Store<Self>) {
    self.store = store
  }

  struct State: ModelState {
    var text: String?
    var string: String?
    var words: String?
    var numbers: [Int] = []
    var value = "DEFAULT_VALUE"
  }

  let store: Store<Self>

  @Route<StringModel> var string
  @Route<TextModel> var text
  @Route<WordsModel> var words
  @RouteList<NumberModel> var numbers

  func route(state: Projection<State>) -> some Routing {
    if let stringState = state.string.compact(),
      stringState.value == "hello string"
    {
      let state = stringState.statefulMap(into: StringModel.State()) { from, to in
        from <-> to.string
      }
      $string.route(state) { store in
        StringModel(store: store)
      }
    }

    if let textState = state.text.compact(),
      textState.value == "hello text"
    {
      let state = textState.statefulMap(into: TextModel.State()) { from, to in
        from <-> to.text
      }
      $text.route(state) { store in
        TextModel(store: store)
      }
    }
    if let wordsState = state.words.compact(),
      wordsState.value == "hello words"
    {
      let state = wordsState.statefulMap(into: WordsModel.State()) { from, to in
        from <-> to.words
      }
      $words.route(state) { store in
        WordsModel(store: store)
      }
    }

    let numbersState = state.statefulMap(into: [NumberValue]()) { from, to in
      let joined = from.numbers.join(from.value) { numbers, value in
        numbers.reduce(into: [NumberValue]()) { acc, number in
          acc.append(NumberValue(number: number, value: value))
        }
      }
      joined --> to
    }

    $numbers.routeForEach(numbersState, into: NumberModel.State()) { from, to in
      from.number --> to.number
      from.value --> to.value
    } model: { _, store in
      NumberModel(store: store)
    }
  }

}

// MARK: - NumberValue

struct NumberValue: Identifiable {
  var id: String { "\(number)" }
  var number: Int
  var value: String
}

// MARK: - Int + Identifiable

extension Int: Identifiable {
  public var id: String { "\(self)" }
}
