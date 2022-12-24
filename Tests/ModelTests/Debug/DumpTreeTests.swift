import Disposable
import Emitter
import Foundation
import Node
import XCTest

@testable import Model

@MainActor
final class DebugOutputTests: XCTestCase {

  var stage: DisposalStage!
  var root: TreeSegment!

  override func setUpWithError() throws {
    stage = .init()
  }

  override func tearDownWithError() throws {
    stage.dispose()
    stage = nil
    root = nil
  }

  func test_dumpTree() throws {
    let tree: TreePath.Segment =
      .root(
        .trunk(
          .trunk(
            .branch(
              .bough(
                .bough(
                  .bough(
                    .branch(
                      .taper(
                        .twig(
                          .twig(
                            .branch(
                              .leaf(
                                .init()
                              ),
                              .twig(
                                .twig(
                                  .branch(
                                    .twig(
                                      .leaf(
                                        .init()
                                      )
                                    ),
                                    .twig(
                                      .twig(
                                        .twig(
                                          .leaf(
                                            .init()
                                          )
                                        )
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          )
                        )
                      ),
                      .taper(.leaf(.init()))
                    )
                  )
                )
              ),
              .bough(.taper(.leaf(.init())))
            )
          )
        )
      )

    root = try TreeSegment.start(
      stage: stage,
      path: tree
    )

    XCTAssertEqual(
      root.dumpTree { ($0 as? TreeSegment)?.type.rawValue ?? "error" },
      """
      | Depth | fn -> _                |
      | ----- | ---------------------- |
      | 0     | root                   |
      | 1     |  trunk                 |
      | 2     |   trunk                |
      | 3     |    bough               |
      | 4     |     bough              |
      | 5     |      bough             |
      | 6     |       bough            |
      | 7     |        bough           |
      | 8     |         twig           |
      | 9     |          twig          |
      | 10    |           twig         |
      | 11    |            twig        |
      | 12    |             leaf       |
      | 11    |            twig        |
      | 12    |             twig       |
      | 13    |              twig      |
      | 14    |               twig     |
      | 15    |                twig    |
      | 16    |                 leaf   |
      | 14    |               twig     |
      | 15    |                twig    |
      | 16    |                 twig   |
      | 17    |                  twig  |
      | 18    |                   leaf |
      | 7     |        bough           |
      | 8     |         twig           |
      | 9     |          leaf          |
      | 3     |    bough               |
      | 4     |     bough              |
      | 5     |      twig              |
      | 6     |       leaf             |
      """
    )
  }

  func test_debugDump() throws {
    let tree: TreePath.Segment =
      .root(
        .trunk(
          .trunk(
            .branch(
              .bough(
                .bough(
                  .bough(
                    .branch(
                      .taper(
                        .twig(
                          .twig(
                            .branch(
                              .leaf(
                                .init()
                              ),
                              .twig(
                                .twig(
                                  .branch(
                                    .twig(
                                      .leaf(
                                        .init()
                                      )
                                    ),
                                    .twig(
                                      .twig(
                                        .twig(
                                          .leaf(
                                            .init()
                                          )
                                        )
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          )
                        )
                      ),
                      .taper(.leaf(.init()))
                    )
                  )
                )
              ),
              .bough(.taper(.leaf(.init())))
            )
          )
        )
      )

    root = try TreeSegment.start(
      stage: stage,
      path: tree
    )
    XCTAssertEqual(
      root.debugDump(),
      """
      ▿ TreeSegment: ModelTests.TreeSegment.State
        - depth: 0
        - name: ""
        - localState: ""
        ▿ segment: ModelTests.TreePath.Segment.root
          ▿ root: ModelTests.TreePath.Root.trunk
            ▿ trunk: ModelTests.TreePath.Trunk.trunk
              ▿ trunk: ModelTests.TreePath.Trunk.branch
                ▿ branch: (2 elements)
                  ▿ .0: ModelTests.TreePath.Bough.bough
                    ▿ bough: ModelTests.TreePath.Bough.bough
                      ▿ bough: ModelTests.TreePath.Bough.bough
                        ▿ bough: ModelTests.TreePath.Bough.branch
                          ▿ branch: (2 elements)
                            ▿ .0: ModelTests.TreePath.Bough.taper
                              ▿ taper: ModelTests.TreePath.Twig.twig
                                ▿ twig: ModelTests.TreePath.Twig.twig
                                  ▿ twig: ModelTests.TreePath.Twig.branch
                                    ▿ branch: (2 elements)
                                      ▿ .0: ModelTests.TreePath.Twig.leaf
                                        - leaf: ModelTests.TreePath.Leaf
                                      ▿ .1: ModelTests.TreePath.Twig.twig
                                        ▿ twig: ModelTests.TreePath.Twig.twig
                                          ▿ twig: ModelTests.TreePath.Twig.branch
                                            ▿ branch: (2 elements)
                                              ▿ .0: ModelTests.TreePath.Twig.twig
                                                ▿ twig: ModelTests.TreePath.Twig.leaf
                                                  - leaf: ModelTests.TreePath.Leaf
                                              ▿ .1: ModelTests.TreePath.Twig.twig
                                                ▿ twig: ModelTests.TreePath.Twig.twig
                                                  ▿ twig: ModelTests.TreePath.Twig.twig
                                                    ▿ twig: ModelTests.TreePath.Twig.leaf
                                                      - leaf: ModelTests.TreePath.Leaf
                            ▿ .1: ModelTests.TreePath.Bough.taper
                              ▿ taper: ModelTests.TreePath.Twig.leaf
                                - leaf: ModelTests.TreePath.Leaf
                  ▿ .1: ModelTests.TreePath.Bough.bough
                    ▿ bough: ModelTests.TreePath.Bough.taper
                      ▿ taper: ModelTests.TreePath.Twig.leaf
                        - leaf: ModelTests.TreePath.Leaf

      """
    )
  }

}
