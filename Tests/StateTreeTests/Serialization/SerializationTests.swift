import Disposable
import Intents
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - SerializationTests

final class SerializationTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() {
    NodeID
      .incrementForTesting()
      .stage(on: stage)
  }

  override func tearDown() {
    stage.reset()
  }

  @TreeActor
  func _test_dump_prime() async throws {
    let tree = Tree(root: PrimeSquare())
    try tree.start()
      .autostop()
      .stage(on: stage)
    try tree.assume.rootNode.potentialPrime = 7
    print("<prime>")
    print(try tree.assume.snapshot().formattedJSON)
    print("</prime>")
  }

  @TreeActor
  func _test_dump_composite() async throws {
    let tree = Tree(root: PrimeSquare())
    try tree.start()
      .autostop()
      .stage(on: stage)
    try tree.assume.rootNode.potentialPrime = 8
    let someIntent = try Intent(
      PrimeSquare.SomeIntentStep(someField: 123, someOtherField: "321"),
      try Step(name: "invalid-pending-step", fields: ["field": "abc"])
    )
    try tree.assume.signal(intent: XCTUnwrap(someIntent))
    print("<composite>")
    print(try tree.assume.snapshot().formattedJSON)
    print("</composite>")
  }

  @TreeActor
  func testEncoding() async throws {
    let tree = Tree(
      root: PrimeSquare()
    )
    try tree.start()
    try tree.assume.rootNode.potentialPrime = 7
    let snapshot = try tree.assume.snapshot()
    let string = snapshot.formattedJSON
    XCTAssertEqual(string, primeStateString)
    XCTAssert(try tree.assume.rootNode.commentaries.first?.note != nil)
  }

  @TreeActor
  func testDecoding() async throws {
    let tree1 = Tree(root: PrimeSquare())
    let state = try TreeStateRecord(jsonString: primeStateString)
    try tree1.start(from: state)
      .autostop()
      .stage(on: stage)
    let snap1 = try tree1.assume.snapshot()
    XCTAssertEqual(snap1.formattedJSON, primeStateString)

    let tree2 = Tree(root: PrimeSquare())
    try tree2.start()
      .autostop()
      .stage(on: stage)
    try tree2.assume.rootNode.potentialPrime = 7
    let snap2 = try tree2.assume.snapshot()
    XCTAssertEqual(snap2.formattedJSON, primeStateString)

    XCTAssertEqual(try tree1.assume.rootID, try tree2.assume.rootID)
    XCTAssertEqual(
      try tree1.assume.rootNode.commentaries.first?.note,
      try tree2.assume.rootNode.commentaries.first?.note
    )
    XCTAssertEqual(
      try tree1.assume.rootNode.primeSquared?.value,
      try tree2.assume.rootNode.primeSquared?.value
    )
    XCTAssertEqual(
      try tree1.assume.rootNode.primeSquared?.square,
      try tree2.assume.rootNode.primeSquared?.square
    )
    XCTAssertEqual(snap1.formattedJSON, snap2.formattedJSON)
  }

  @TreeActor
  func testAlternateEncoding() async throws {
    let tree = Tree(
      root: PrimeSquare()
    )
    try tree.start()
    let someIntent = try Intent(
      PrimeSquare.SomeIntentStep(someField: 123, someOtherField: "321"),
      try Step(name: "invalid-pending-step", fields: ["field": "abc"])
    )
    try tree.assume.signal(intent: XCTUnwrap(someIntent))
    try tree.assume.rootNode.potentialPrime = 8
    let snapshot = try tree.assume.snapshot()
    let string = snapshot.formattedJSON
    XCTAssertEqual(string, compositeStateString)
  }

  @TreeActor
  func testAlternateState() async throws {
    let state = try TreeStateRecord(jsonString: compositeStateString)
    let tree = Tree(
      root: PrimeSquare()
    )
    try tree.start(from: state)
      .autostop()
      .stage(on: stage)
    let snap = try tree.assume.snapshot()
    XCTAssertEqual(snap.formattedJSON, compositeStateString)
  }
}

// MARK: - TestKey

private struct TestKey: DependencyKey {
  static let defaultValue = "Some Text"
}

extension DependencyValues {
  fileprivate var testDep: String {
    get { self[TestKey.self] }
    set { self[TestKey.self] = newValue }
  }
}

extension SerializationTests {

  // MARK: - Commentary

  struct Commentary: Node, Identifiable {
    let id: String
    @Value var note: String
    @Dependency(\.testDep) var testDependency
    var rules: some Rules { .none }
  }

  // MARK: - Square

  struct Square: Node {

    @Value var square: Int!
    @Projection var value: Int

    var rules: some Rules {
      OnUpdate(value) { newValue in
        square = newValue * newValue
      }
    }
  }

  // MARK: - PrimeSquare

  struct PrimeSquare: Node {

    // MARK: Internal

    struct SomeIntentStep: IntentStepPayload {
      static let name = "some-intent"
      let someField: Int
      let someOtherField: String
    }

    @Value var potentialPrime = 0
    @Route var primeSquared: Square? = nil
    @Scope var scope
    @Route var commentaries: [Commentary] = []

    var rules: some Rules {
      if isPrime(potentialPrime) {
        Attach(
          $primeSquared,
          to: Square(value: $potentialPrime)
        )
        Attach(
          $commentaries,
          to: [
            Commentary(id: "yes1", note: "It's a prime!"),
            Commentary(id: "yes2", note: "really!"),
          ]
        )
      } else {
        Attach(
          $commentaries,
          to: [
            Commentary(id: "no1", note: "Not a prime :("),
            Commentary(id: "no2", note: "srsly"),
          ]
        )
      }
      OnIntent(SomeIntentStep.self) { _ in
        // keep the intent pending to keep it present in the state.
        .pend
      }
    }

    // MARK: Private

    private func isPrime(_ num: Int) -> Bool {
      guard num >= 2 else {
        return false
      }
      guard num != 2 else {
        return true
      }
      guard num % 2 != 0 else {
        return false
      }
      return !stride(
        from: 3,
        through: Int(sqrt(Double(num))),
        by: 2
      ).contains { num % $0 == 0 }
    }

  }

}

extension SerializationTests {
  var primeStateString: String {
    """
    {
      "activeIntent" : null,
      "nodes" : [
        {
          "id" : "00000000-1111-1111-1111-111111111111",
          "origin" : {
            "depth" : 0,
            "fieldID" : "r:0:00000000-0000-0000-0000-000000000000",
            "type" : "single"
          },
          "records" : [
            {
              "id" : "v:0:00000000-1111-1111-1111-111111111111",
              "payload" : {
                "value" : {
                  "_0" : "7"
                }
              }
            },
            {
              "id" : "r:1:00000000-1111-1111-1111-111111111111",
              "payload" : {
                "route" : {
                  "_0" : {
                    "maybeSingle" : {
                      "_0" : "00000000-FFFF-0000-0000-000000000003"
                    }
                  }
                }
              }
            },
            {
              "id" : "s:2:00000000-1111-1111-1111-111111111111"
            },
            {
              "id" : "r:3:00000000-1111-1111-1111-111111111111",
              "payload" : {
                "route" : {
                  "_0" : {
                    "list" : {
                      "_0" : {
                        "idMap" : [
                          "0",
                          "00000000-FFFF-0000-0000-000000000001",
                          "1",
                          "00000000-FFFF-0000-0000-000000000002"
                        ]
                      }
                    }
                  }
                }
              }
            }
          ]
        },
        {
          "id" : "00000000-FFFF-0000-0000-000000000001",
          "origin" : {
            "depth" : 0,
            "fieldID" : "r:3:00000000-1111-1111-1111-111111111111",
            "type" : "union2"
          },
          "records" : [
            {
              "id" : "u:0:00000000-FFFF-0000-0000-000000000001"
            },
            {
              "id" : "v:1:00000000-FFFF-0000-0000-000000000001",
              "payload" : {
                "value" : {
                  "_0" : "\\"Not a prime :(\\""
                }
              }
            },
            {
              "id" : "d:2:00000000-FFFF-0000-0000-000000000001"
            }
          ]
        },
        {
          "id" : "00000000-FFFF-0000-0000-000000000002",
          "origin" : {
            "depth" : 0,
            "fieldID" : "r:3:00000000-1111-1111-1111-111111111111",
            "type" : "union2"
          },
          "records" : [
            {
              "id" : "u:0:00000000-FFFF-0000-0000-000000000002"
            },
            {
              "id" : "v:1:00000000-FFFF-0000-0000-000000000002",
              "payload" : {
                "value" : {
                  "_0" : "\\"srsly\\""
                }
              }
            },
            {
              "id" : "d:2:00000000-FFFF-0000-0000-000000000002"
            }
          ]
        },
        {
          "id" : "00000000-FFFF-0000-0000-000000000003",
          "origin" : {
            "depth" : 0,
            "fieldID" : "r:1:00000000-1111-1111-1111-111111111111",
            "type" : "maybeSingle"
          },
          "records" : [
            {
              "id" : "v:0:00000000-FFFF-0000-0000-000000000003",
              "payload" : {
                "value" : {
                  "_0" : "49"
                }
              }
            },
            {
              "id" : "p:1:00000000-FFFF-0000-0000-000000000003",
              "payload" : {
                "projection" : {
                  "_0" : {
                    "valueField" : {
                      "_0" : "v:0:00000000-1111-1111-1111-111111111111"
                    }
                  }
                }
              }
            }
          ]
        }
      ]
    }
    """
  }

  var compositeStateString: String {
    """
    {
      "activeIntent" : {
        "consumerIDs" : [
          "00000000-1111-1111-1111-111111111111"
        ],
        "intentPayload" : {
          "steps" : [
            {
              "name" : "some-intent",
              "payload" : {
                "someField" : 123,
                "someOtherField" : "321"
              }
            },
            {
              "name" : "invalid-pending-step",
              "payload" : {
                "field" : "abc"
              }
            }
          ]
        },
        "lastConsumerID" : "00000000-1111-1111-1111-111111111111"
      },
      "nodes" : [
        {
          "id" : "00000000-1111-1111-1111-111111111111",
          "origin" : {
            "depth" : 0,
            "fieldID" : "r:0:00000000-0000-0000-0000-000000000000",
            "type" : "single"
          },
          "records" : [
            {
              "id" : "v:0:00000000-1111-1111-1111-111111111111",
              "payload" : {
                "value" : {
                  "_0" : "8"
                }
              }
            },
            {
              "id" : "r:1:00000000-1111-1111-1111-111111111111",
              "payload" : {
                "route" : {
                  "_0" : {
                    "maybeSingle" : {

                    }
                  }
                }
              }
            },
            {
              "id" : "s:2:00000000-1111-1111-1111-111111111111"
            },
            {
              "id" : "r:3:00000000-1111-1111-1111-111111111111",
              "payload" : {
                "route" : {
                  "_0" : {
                    "list" : {
                      "_0" : {
                        "idMap" : [
                          "0",
                          "00000000-FFFF-0000-0000-000000000001",
                          "1",
                          "00000000-FFFF-0000-0000-000000000002"
                        ]
                      }
                    }
                  }
                }
              }
            }
          ]
        },
        {
          "id" : "00000000-FFFF-0000-0000-000000000001",
          "origin" : {
            "depth" : 0,
            "fieldID" : "r:3:00000000-1111-1111-1111-111111111111",
            "type" : "union2"
          },
          "records" : [
            {
              "id" : "u:0:00000000-FFFF-0000-0000-000000000001"
            },
            {
              "id" : "v:1:00000000-FFFF-0000-0000-000000000001",
              "payload" : {
                "value" : {
                  "_0" : "\\"Not a prime :(\\""
                }
              }
            },
            {
              "id" : "d:2:00000000-FFFF-0000-0000-000000000001"
            }
          ]
        },
        {
          "id" : "00000000-FFFF-0000-0000-000000000002",
          "origin" : {
            "depth" : 0,
            "fieldID" : "r:3:00000000-1111-1111-1111-111111111111",
            "type" : "union2"
          },
          "records" : [
            {
              "id" : "u:0:00000000-FFFF-0000-0000-000000000002"
            },
            {
              "id" : "v:1:00000000-FFFF-0000-0000-000000000002",
              "payload" : {
                "value" : {
                  "_0" : "\\"srsly\\""
                }
              }
            },
            {
              "id" : "d:2:00000000-FFFF-0000-0000-000000000002"
            }
          ]
        }
      ]
    }
    """
  }
}
