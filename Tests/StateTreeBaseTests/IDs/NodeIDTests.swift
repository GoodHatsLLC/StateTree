import Disposable
import Emitter
import XCTest
@_spi(Implementation) @testable import StateTreeBase

final class NodeIDTests: XCTestCase {

  // MARK: Internal

  override func setUp() { }
  override func tearDown() { }

  func test_root() throws {
    XCTAssertNotEqual(NodeID.root, NodeID.invalid)
  }

  func test_nodeID_ordering() throws {
    let uuids = (0 ..< 100).map { n in
      num(n)
    }
    let shuffled = uuids.shuffled()
    let nodeIDs = shuffled.map { NodeID(uuid: $0) }
    XCTAssertNotEqual(nodeIDs.map(\.description), uuids.map(\.uuidString))
    let sorted = nodeIDs.sorted()
    XCTAssertEqual(sorted.map(\.description), uuids.map(\.uuidString))
  }

  func test_nodeID_metadata_encoding() throws {
    let uuid = UUID()
    let nodeIDString = "\(uuid.description)"
    let nodeID = try XCTUnwrap(NodeID(nodeIDString))
    XCTAssertEqual(nodeID.description, nodeIDString)
    XCTAssertEqual(nodeID.uuid, uuid)
  }

  func test_nodeID_uuidV4_metadata_encoding() throws {
    let uuidString = "9AD2F770-E559-4B95-8EB4-EDC5ACD1FF39"
    let uuid = UUID(uuidString: uuidString)
    let nodeIDString = "\(uuidString)"
    let nodeID = try XCTUnwrap(NodeID(nodeIDString))
    XCTAssertEqual(nodeID.uuid, uuid)
  }

  func test_nodeID_badInputs() throws {
    XCTAssertNil(NodeID("1ED8F432-BB3A-6AC8-B23F-25E1E475E50[aaa]"))
    XCTAssertNil(NodeID("1ED8F432-BB3A-6AC8-B23F-25E1E475E502]"))
    XCTAssertNil(NodeID("1ED8F432-BB3A-6AC8-B23F-25E1E475E502["))
    XCTAssertNil(NodeID("1ED8F432-BB3A-6AC8-B23F-25E1E475E502aaa"))
    XCTAssertNil(NodeID("aaa"))
  }

  // MARK: Fileprivate

  fileprivate func num(_ num: Int) -> UUID {
    let numStr = String(num)
    let padded = String(repeating: "0", count: 12 - numStr.count) + numStr
    return UUID(
      uuidString: "00000000-FFFF-0000-0000-\(padded)"
    )!
  }

}
