# 🌳 StateTree

StateTree won't be developed in its current form beyond `v0.0.10`.

StateTree `v0.0.10` was a semi-successful experiment in applying declarative
routing to the application domain logic without using a Redux model.

Logic writen with StateTree:
* Is declarative
* Is fully independent of the UI layer
* Has no proprietary dependencies (like Combine)
* Has native-feeling SwiftUI integration
* Has simple imperative UIKit compatibility
* Automatically supports time-travel-debugging
* Has excellent unit testing support — including side effect interception
* Is simple to integrate with SwiftUI Previews

![SwiftUI TicTacToe App](https://user-images.githubusercontent.com/509838/210757910-6cf03b58-0e39-4c3b-828e-c50c253c3ffe.gif)

## Retrospective

This project involved a bunch of hypothesis testing and a lot of research.
StateTree works — and seems stable! It has proved out some of what it intended!

1. Declarative routing applies nicely to domain logic — and
   it's probably not too slow for production usage.
2. A system doing it can be integrated nicely into SwiftUI.
3. The same system can have alternative frontends.
4. It's possible to make a system that treats bidirectional
   mapping as a first class concept and works reliably.

But the API it provided was rough to work with.

* It was awkward to work with an explicit 'Store' object.
* It's nicer to work with granular values like the `@StoreValue`
  than larger blobs like the current structs conforming to `State`.
* Per-model storage meant having to write significant and often fragile
  mapping logic.  
  It's possible to write a DSL like `Bimapping` to make this easier — but
  doing so didn't fix the root issue.
* Some of Redux model's gotchas are present in or echoed by StateTree.
  It ends up similarly necessary to normalize app state increasing complexity and
  separating the conceptual source of truth.
* Bidirectional mapping is hard when applied to anything more complicated
  than subsets. `Projection` makes it more flexible than SwiftUI's `Binding` allows
  — but one quickly reaches for logic that's harder to write than is desirable.

The results largely support the conventional wisdom favoring Unidirectional data-flow.  
StateTree `v0.0.10` exposes Bidirection model to users more than SwiftUI itself does.
This wasn't a design goal. `v0.0.10`'s implementation of multi-store sources of truth
(`Nodes`) were dependent on bidirectional mapping, and the paradigm leaked through the API.

The `Node` tree's up-and-back-down-propagation model *does* work to smudge over the some
of the wrinkles in the split-source-of-truth model—but it had a high complexity cost.

## Themes for what's next

I remain bullish on the value of applying a declarative paradigm to domain logic.  
`v0.0.10` largely reinforced this.  
Notably however, StateTree `v0.0.10` mostly failed in its goal of providing evidence
of an alternative to the Redux model.  

Future work will focus on:
* DAG-like modelling and behavior.
* Minimising bidirectional mapping.
* Allowing more granular state definitons.
* Avoiding explicit stores and generally improving ergonomics.
* Enable global actors beyond `@MainActor`. In Swift 5.7.

-----

## Examples

The repo bundles example projects:
* SwiftUI based [TicTacToe app](https://github.com/GoodHatsLLC/StateTree/tree/main/Examples/TicTacToe)
    * Time-travel debugging / state playback
    * SwiftUI preview integration
* UIKit based [Counters app](https://github.com/GoodHatsLLC/StateTree/tree/main/Examples/Counter)
    * Proof of concept for integration with imperative UI
    * Uses array index based routing
* SwiftUI based [ToDo app](https://github.com/GoodHatsLLC/StateTree/tree/main/Examples/ToDo)
    * `NavigationLink` and `NavigationSplitView` use
    * Most complicated routing example, showing changes based on selection ids

### SwiftUI TicTacToe
![SwiftUI TicTacToe App](https://user-images.githubusercontent.com/509838/201757307-b719a9e1-4a03-4186-9375-452975d986d8.gif)

### UIKit Counters
![UIKit Counters App](https://user-images.githubusercontent.com/509838/204498714-a519ae4b-cfb3-4fa9-b9d7-309a17435027.gif)

### SwiftUI ToDos
![SwiftUI ToDo App](https://user-images.githubusercontent.com/509838/204482543-c5ba1524-790f-4654-b764-d49593007b67.gif)

## What it can do
* Multi-store (per-model) state
* Declarative state based routing between domains/models
    * Optional routes
    * List routes
* UI layer integration 
    * Native-feeling SwiftUI integration
    * Easy SwiftUI Previews support
    * Prototype UIKit/callback support
* Model bound 'Behaviors' facilitating side-effects and I/O
    * Test utilities for mocking and verifying Behavior execution
* Time-travel debugging support. 
    * i.e. State recording and playback.
* Tree-scoped dependency injection styled after SwiftUI's `@Environment`.
* Lifecycle events hooks. e.g. 'didActivate', 'didUpdate'
* Update events which trigger only for observed state.

## Understanding StateTree's `v0.0.10`'s model

For now, the best way to get a sense of how you'd use state tree is to follow the code:

1. [Tree](https://github.com/GoodHatsLLC/StateTree/blob/main/Sources/Tree/Tree.swift) is the root object containing the model tree.
2. See the tree and root model started up in the [ToDoApp example](https://github.com/GoodHatsLLC/StateTree/blob/main/Examples/ToDo/ToDo/ToDoApp.swift)
3. The ToDo example's [ToDoManager](https://github.com/GoodHatsLLC/StateTree/blob/main/Examples/ToDo/ToDoSupport/Sources/ToDoDomain/ToDoManager.swift) is its core domain model.  
Step back from the UI and into the domain logic code that StateTree is centered around. 
4. Look at how the ToDoManager interacts with its routed submodel, the [SelectedToDo](https://github.com/GoodHatsLLC/StateTree/blob/main/Examples/ToDo/ToDoSupport/Sources/ToDoDomain/SelectedToDo.swift).
5. Given a sense of how domain logic written with StateTree holds together, look at how the domain models can be used in SwiftUI [as the domain layer behind your view models](https://github.com/GoodHatsLLC/StateTree/tree/main/Examples/ToDo/ToDoSupport/Sources/ToDoUI/Selected) — or for simpler setups [directly as your observable objects](https://github.com/GoodHatsLLC/StateTree/blob/main/Examples/TicTacToe/GameSupport/Sources/GameUI/ScoreBoardView.swift).

### Understanding the implementation

To get a sense of the implementation follow the code on the hot-path of state updates.  
It's reasonably well commented.

* Follow the [`Store`](https://github.com/GoodHatsLLC/StateTree/blob/main/Sources/Model/Model/Store.swift) that's exposed to consumers through to its backing [`_ModelStorage`](https://github.com/GoodHatsLLC/StateTree/blob/main/Sources/Model/Model/Storage/_ModelStorage.swift)
* Follow `_ModelStorage` structs's [`start(model:meta:annotations)`](https://github.com/GoodHatsLLC/StateTree/blob/main/Sources/Model/Model/Storage/_ModelStorage.swift#L211) call through to the [`ActiveModel`](https://github.com/GoodHatsLLC/StateTree/blob/main/Sources/Model/Model/Storage/ActiveModel.swift).  
(Note that `ActiveModel` exists only while the store is actually started/active.)
* Follow `ActiveModel's` [`write(_:)`](https://github.com/GoodHatsLLC/StateTree/blob/main/Sources/Model/Model/Storage/ActiveModel.swift#L369) call through to the actual underlying `Node` storage.  
Look at the state update/write entrypoint [`updateIfNeeded(state:)`](https://github.com/GoodHatsLLC/StateTree/blob/main/Sources/Node/Node.swift#L171) and follow the logic from there.
* Finally look at how the `ActiveModel` calls out to the consumer `Model` implementations's [`route(state:)`](https://github.com/GoodHatsLLC/StateTree/blob/main/Sources/Model/Model/Storage/ActiveModel.swift#L405) blocks—  
— And then how it [registers itself with its `Node`](https://github.com/GoodHatsLLC/StateTree/blob/main/Sources/Model/Model/Storage/ActiveModel.swift#L236) to do so as part of resolving state changes.

Clear as mud!
