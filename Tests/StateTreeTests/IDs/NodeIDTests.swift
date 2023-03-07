import Emitter
import XCTest
@_spi(Implementation) @testable import StateTree

final class NodeIDTests: XCTestCase {

  override func setUp() { }
  override func tearDown() { }

  func test_root() throws {
    XCTAssertNotEqual(NodeID.root, NodeID.invalid)
  }

  func test_nodeID_metadata_encoding() throws {
    let uuid = UUID()
    let metadata = "x[yz"
    let nodeIDString = "\(uuid.description):\(metadata)"
    let nodeID = try XCTUnwrap(NodeID(nodeIDString))
    XCTAssertEqual(nodeID.description, nodeIDString)
    XCTAssertEqual(nodeID.uuid, uuid)
    XCTAssertEqual(nodeID.cuid, CUID(metadata))
  }

  func test_nodeID_uuidV4_metadata_encoding() throws {
    let uuidString = "9AD2F770-E559-4B95-8EB4-EDC5ACD1FF39"
    let uuid = UUID(uuidString: uuidString)
    let metadata = "[123:abc"
    let nodeIDString = "\(uuidString):\(metadata)"
    let nodeID = try XCTUnwrap(NodeID(nodeIDString))
    XCTAssertEqual(nodeID.uuid, uuid)
    XCTAssertEqual(nodeID.cuid, CUID(metadata))
  }

  func test_nodeID_noMetadata() throws {
    let uuidString = "9AD2F770-E559-4B95-8EB4-EDC5ACD1FF39"
    let uuid = UUID(uuidString: uuidString)
    let nodeIDString = "\(uuidString):"
    let nodeID = try XCTUnwrap(NodeID(nodeIDString))
    XCTAssertEqual(nodeID.uuid, uuid)
    XCTAssertNil(nodeID.cuid)
  }

  func test_nodeID_emptyMetadata() throws {
    let nodeID = try XCTUnwrap(NodeID("9AD2F770-E559-4B95-8EB4-EDC5ACD1FF39:"))
    XCTAssertNil(nodeID.cuid)
  }

  func test_nodeID_badInputs() throws {
    XCTAssertNil(NodeID("1ED8F432-BB3A-6AC8-B23F-25E1E475E50[aaa]"))
    XCTAssertNil(NodeID("1ED8F432-BB3A-6AC8-B23F-25E1E475E502]"))
    XCTAssertNil(NodeID("1ED8F432-BB3A-6AC8-B23F-25E1E475E502["))
    XCTAssertNil(NodeID("1ED8F432-BB3A-6AC8-B23F-25E1E475E502aaa"))
    XCTAssertNil(NodeID("aaa"))
  }
}
