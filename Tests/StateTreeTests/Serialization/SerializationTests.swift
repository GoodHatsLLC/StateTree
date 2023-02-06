import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - SerializationTests

@TreeActor
final class SerializationTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() {
    XCTAssertNil(Tree.main._info)
    NodeID
      .incrementForTesting()
      .stage(on: stage)
  }

  override func tearDown() {
    stage.reset()
  }

  func _test_dump_prime() throws {
    let life = try Tree()
      .start(
        root: PrimeSquare()
      )
    life.stage(on: stage)
    life.rootNode.potentialPrime = 7
    print(life.snapshot().formattedJSON)
  }

  func _test_dump_nonprime() throws {
    let life = try Tree()
      .start(
        root: PrimeSquare()
      )
    life.stage(on: stage)
    life.rootNode.potentialPrime = 8
    let someIntent = Intent(
      PrimeSquare.SomeIntentStep(someField: 123, someOtherField: "321"),
      Step(name: "invalid-pending-step", fields: ["field": "abc"])
    )
    try life.signal(intent: XCTUnwrap(someIntent))
    print(life.snapshot().formattedJSON)
  }

  func testEncoding() throws {
    let tree = try Tree.main
      .start(
        root: PrimeSquare()
      )
    tree.stage(on: stage)
    tree.rootNode.potentialPrime = 7
    let snapshot = tree.snapshot()
    let string = snapshot.formattedJSON
    XCTAssertEqual(string, primeStateString)
    XCTAssert(tree.rootNode.commentaries?[0].note != nil)
  }

  func testDecoding() throws {
    let state = try TreeStateRecord(formattedJSON: primeStateString)
    let tree1 = try Tree().start(
      root: PrimeSquare(),
      from: state
    )
    tree1.stage(on: stage)
    let snap1 = tree1.snapshot()
    XCTAssertEqual(snap1.formattedJSON, primeStateString)

    let tree2 = try Tree()
      .start(root: PrimeSquare())
    tree2.stage(on: stage)
    tree2.rootNode.potentialPrime = 7
    let snap2 = tree2.snapshot()
    XCTAssertEqual(snap2.formattedJSON, primeStateString)

    XCTAssertEqual(tree1.rootID, tree2.rootID)
    XCTAssertEqual(tree1.rootNode.commentaries?[0].note, tree2.rootNode.commentaries?[0].note)
    XCTAssertEqual(tree1.rootNode.primeSquared?.value, tree2.rootNode.primeSquared?.value)
    XCTAssertEqual(tree1.rootNode.primeSquared?.square, tree2.rootNode.primeSquared?.square)
    XCTAssertEqual(snap1, snap2)
  }

  func testAlternateEncoding() throws {
    let tree = try Tree.main
      .start(
        root: PrimeSquare()
      )
    tree.stage(on: stage)
    let someIntent = Intent(
      PrimeSquare.SomeIntentStep(someField: 123, someOtherField: "321"),
      Step(name: "invalid-pending-step", fields: ["field": "abc"])
    )
    try tree.signal(intent: XCTUnwrap(someIntent))
    tree.rootNode.potentialPrime = 8
    let snapshot = tree.snapshot()
    let string = snapshot.formattedJSON
    XCTAssertEqual(string, nonPrimeStateString)
  }

  func testAlternateState() throws {
    let state = try TreeStateRecord(formattedJSON: nonPrimeStateString)
    let life = try Tree().start(
      root: PrimeSquare(),
      from: state
    )
    life.stage(on: stage)
    let snap = life.snapshot()
    XCTAssertEqual(snap.formattedJSON, nonPrimeStateString)
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
      OnChange(value) { newValue in
        square = newValue * newValue
      }
    }
  }

  // MARK: - PrimeSquare

  struct PrimeSquare: Node {

    // MARK: Internal

    struct SomeIntentStep: IntentStep {
      static let name = "some-intent"
      let someField: Int
      let someOtherField: String
    }

    let useUpper = false

    @Value var potentialPrime = 0
    @Route(Square.self) var primeSquared
    @Scope var scope
    @Route([Commentary].self) var commentaries

    var rules: some Rules {
      if isPrime(potentialPrime) {
        $primeSquared.route {
          Square(value: $potentialPrime)
        }

        $commentaries.route {
          let text = "It's a prime!"
          return [
            Commentary(id: "yes1", note: useUpper ? text.uppercased() : text),
            Commentary(id: "yes2", note: "really!"),
          ]
        }
      } else {
        $commentaries.route {
          let text = "Not a prime :("
          return [
            Commentary(id: "no1", note: useUpper ? text.uppercased() : text),
            Commentary(id: "no2", note: "srsly"),
          ]
        }
      }
      OnIntent(step: SomeIntentStep.self) { _ in
        // keep the intent pending to keep it present in the state.
        .pending
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
          "id" : "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
          "origin" : {
            "fieldID" : "r:0:00000000-0000-0000-0000-000000000000:⚡️",
            "type" : "single"
          },
          "records" : [
            {
              "id" : "u:0:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "useUpper",
                "typeof" : "Bool"
              }
            },
            {
              "id" : "v:1:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "_potentialPrime",
                "typeof" : "Value<Int>"
              },
              "payload" : {
                "value" : {
                  "_0" : 7
                }
              }
            },
            {
              "id" : "r:2:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "_primeSquared",
                "typeof" : "Route<SingleRouter<Square>>"
              },
              "payload" : {
                "route" : {
                  "_0" : {
                    "single" : {
                      "_0" : {
                        "id" : "F0000000-F000-F000-F000-000000000003:"
                      }
                    }
                  }
                }
              }
            },
            {
              "id" : "s:3:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "_scope",
                "typeof" : "Scope"
              }
            },
            {
              "id" : "r:4:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "_commentaries",
                "typeof" : "Route<ListRouter<Commentary>>"
              },
              "payload" : {
                "route" : {
                  "_0" : {
                    "list" : {
                      "_0" : [
                        {
                          "key" : "yes1",
                          "val" : "F0000000-F000-F000-F000-000000000004:"
                        },
                        {
                          "key" : "yes2",
                          "val" : "F0000000-F000-F000-F000-000000000005:"
                        }
                      ]
                    }
                  }
                }
              }
            }
          ]
        },
        {
          "id" : "F0000000-F000-F000-F000-000000000003:",
          "origin" : {
            "fieldID" : "r:2:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
            "type" : "single"
          },
          "records" : [
            {
              "id" : "v:0:F0000000-F000-F000-F000-000000000003:",
              "meta" : {
                "label" : "_square",
                "typeof" : "Value<Optional<Int>>"
              },
              "payload" : {
                "value" : {
                  "_0" : 49
                }
              }
            },
            {
              "id" : "p:1:F0000000-F000-F000-F000-000000000003:",
              "meta" : {
                "label" : "_value",
                "typeof" : "Projection<Int>"
              },
              "payload" : {
                "projection" : {
                  "_0" : {
                    "valueField" : {
                      "_0" : "v:1:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳"
                    }
                  }
                }
              }
            }
          ]
        },
        {
          "id" : "F0000000-F000-F000-F000-000000000004:",
          "origin" : {
            "fieldID" : "r:4:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
            "identity" : "yes1",
            "type" : "list"
          },
          "records" : [
            {
              "id" : "u:0:F0000000-F000-F000-F000-000000000004:",
              "meta" : {
                "label" : "id",
                "typeof" : "String"
              }
            },
            {
              "id" : "v:1:F0000000-F000-F000-F000-000000000004:",
              "meta" : {
                "label" : "_note",
                "typeof" : "Value<String>"
              },
              "payload" : {
                "value" : {
                  "_0" : "It's a prime!"
                }
              }
            },
            {
              "id" : "d:2:F0000000-F000-F000-F000-000000000004:",
              "meta" : {
                "label" : "_testDependency",
                "typeof" : "Dependency<String>"
              }
            }
          ]
        },
        {
          "id" : "F0000000-F000-F000-F000-000000000005:",
          "origin" : {
            "fieldID" : "r:4:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
            "identity" : "yes2",
            "type" : "list"
          },
          "records" : [
            {
              "id" : "u:0:F0000000-F000-F000-F000-000000000005:",
              "meta" : {
                "label" : "id",
                "typeof" : "String"
              }
            },
            {
              "id" : "v:1:F0000000-F000-F000-F000-000000000005:",
              "meta" : {
                "label" : "_note",
                "typeof" : "Value<String>"
              },
              "payload" : {
                "value" : {
                  "_0" : "really!"
                }
              }
            },
            {
              "id" : "d:2:F0000000-F000-F000-F000-000000000005:",
              "meta" : {
                "label" : "_testDependency",
                "typeof" : "Dependency<String>"
              }
            }
          ]
        }
      ]
    }
    """
  }

  var nonPrimeStateString: String {
    """
    {
      "activeIntent" : {
        "intent" : {
          "head" : {
            "name" : "some-intent",
            "underlying" : {
              "fields" : {
                "someField" : 123,
                "someOtherField" : "321"
              }
            }
          },
          "tailSteps" : [
            {
              "name" : "invalid-pending-step",
              "underlying" : {
                "fields" : {
                  "field" : "abc"
                }
              }
            }
          ]
        },
        "lastNodeID" : "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
        "usedNodeIDs" : [
          "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳"
        ]
      },
      "nodes" : [
        {
          "id" : "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
          "origin" : {
            "fieldID" : "r:0:00000000-0000-0000-0000-000000000000:⚡️",
            "type" : "single"
          },
          "records" : [
            {
              "id" : "u:0:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "useUpper",
                "typeof" : "Bool"
              }
            },
            {
              "id" : "v:1:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "_potentialPrime",
                "typeof" : "Value<Int>"
              },
              "payload" : {
                "value" : {
                  "_0" : 8
                }
              }
            },
            {
              "id" : "r:2:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "_primeSquared",
                "typeof" : "Route<SingleRouter<Square>>"
              },
              "payload" : {
                "route" : {
                  "_0" : {
                    "single" : {

                    }
                  }
                }
              }
            },
            {
              "id" : "s:3:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "_scope",
                "typeof" : "Scope"
              }
            },
            {
              "id" : "r:4:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
              "meta" : {
                "label" : "_commentaries",
                "typeof" : "Route<ListRouter<Commentary>>"
              },
              "payload" : {
                "route" : {
                  "_0" : {
                    "list" : {
                      "_0" : [
                        {
                          "key" : "no1",
                          "val" : "F0000000-F000-F000-F000-000000000001:"
                        },
                        {
                          "key" : "no2",
                          "val" : "F0000000-F000-F000-F000-000000000002:"
                        }
                      ]
                    }
                  }
                }
              }
            }
          ]
        },
        {
          "id" : "F0000000-F000-F000-F000-000000000001:",
          "origin" : {
            "fieldID" : "r:4:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
            "identity" : "no1",
            "type" : "list"
          },
          "records" : [
            {
              "id" : "u:0:F0000000-F000-F000-F000-000000000001:",
              "meta" : {
                "label" : "id",
                "typeof" : "String"
              }
            },
            {
              "id" : "v:1:F0000000-F000-F000-F000-000000000001:",
              "meta" : {
                "label" : "_note",
                "typeof" : "Value<String>"
              },
              "payload" : {
                "value" : {
                  "_0" : "Not a prime :("
                }
              }
            },
            {
              "id" : "d:2:F0000000-F000-F000-F000-000000000001:",
              "meta" : {
                "label" : "_testDependency",
                "typeof" : "Dependency<String>"
              }
            }
          ]
        },
        {
          "id" : "F0000000-F000-F000-F000-000000000002:",
          "origin" : {
            "fieldID" : "r:4:FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF:🌳",
            "identity" : "no2",
            "type" : "list"
          },
          "records" : [
            {
              "id" : "u:0:F0000000-F000-F000-F000-000000000002:",
              "meta" : {
                "label" : "id",
                "typeof" : "String"
              }
            },
            {
              "id" : "v:1:F0000000-F000-F000-F000-000000000002:",
              "meta" : {
                "label" : "_note",
                "typeof" : "Value<String>"
              },
              "payload" : {
                "value" : {
                  "_0" : "srsly"
                }
              }
            },
            {
              "id" : "d:2:F0000000-F000-F000-F000-000000000002:",
              "meta" : {
                "label" : "_testDependency",
                "typeof" : "Dependency<String>"
              }
            }
          ]
        }
      ]
    }
    """
  }
}