import Disposable
import Intents
import OrderedCollections
import StateTree
import Utilities
import XCTest
@_spi(Implementation) @testable import StateTree

// MARK: - SerializationBugTests

final class SerializationBugTests: XCTestCase {

  func test_payload_string_encodeDecode() async throws {
    let content = ToDoRecord(id: "one", title: "one", note: "one", dueDate: nil, completed: true)
    let data = try JSONEncoder().encode(content)
    let stringData = try XCTUnwrap(String(data: data, encoding: .utf8))
    let unStringData = try XCTUnwrap(stringData.data(using: .utf8))
    let decoded = try JSONDecoder().decode(ToDoRecord.self, from: unStringData)
    XCTAssertEqual(content, decoded)
  }

  func test_ValuePayload_directExtract() async throws {
    let content = ToDoRecord(id: "one", title: "one", note: "one", dueDate: nil, completed: true)
    var valueRecord = try ValuePayload(content)
    let extractContent = try valueRecord.extract(as: ToDoRecord.self)
    XCTAssertEqual(content, extractContent)
  }

  func test_ValuePayload_encode() async throws {
    let content = ToDoRecord(id: "one", title: "one", note: "one", dueDate: nil, completed: true)
    let valueRecord = try ValuePayload(content)
    XCTAssertNoThrow(try JSONEncoder().encode(valueRecord))
  }

  func test_ValuePayload_decode() async throws {
    let content = ToDoRecord(id: "one", title: "one", note: "one", dueDate: nil, completed: true)
    let valueRecord = try ValuePayload(content)
    let data = try JSONEncoder().encode(valueRecord)
    XCTAssertNoThrow(try JSONDecoder().decode(ValuePayload.self, from: data))
  }

  func test_ValuePayload_decodeExtract() async throws {
    let content = ToDoRecord(id: "one", title: "one", note: "one", dueDate: nil, completed: true)
    let valueRecord = try ValuePayload(content)
    let data = try JSONEncoder().encode(valueRecord)
    var decodeRecord = try JSONDecoder().decode(ValuePayload.self, from: data)
    let extractContent = try decodeRecord.extract(as: ToDoRecord.self)
    XCTAssertEqual(content, extractContent)
  }

  func test_ValuePayload_decoded_preExtractPostExtract_equality() async throws {
    let content = ToDoRecord(id: "one", title: "one", note: "one", dueDate: nil, completed: true)
    let valueRecord = try ValuePayload(content)
    let data = try JSONEncoder().encode(valueRecord)
    let decodeRecord = try JSONDecoder().decode(ValuePayload.self, from: data)
    let preExtract = decodeRecord
    var postExtract = decodeRecord
    _ = try postExtract.extract(as: ToDoRecord.self)
    XCTAssertEqual(valueRecord, preExtract)
    XCTAssertEqual(valueRecord, postExtract)
  }

  func test_ValuePayload_decoded_preExtractPostExtract_hashValue() async throws {
    let content = ToDoRecord(id: "one", title: "one", note: "one", dueDate: nil, completed: true)
    let valueRecord = try ValuePayload(content)
    let data = try JSONEncoder().encode(valueRecord)
    let decodeRecord = try JSONDecoder().decode(ValuePayload.self, from: data)
    let preExtract = decodeRecord
    var postExtract = decodeRecord
    _ = try postExtract.extract(as: ToDoRecord.self)
    XCTAssertEqual(valueRecord.hashValue, preExtract.hashValue)
    XCTAssertEqual(valueRecord.hashValue, postExtract.hashValue)
  }

  func test_ValuePayload_stringIntermediate() async throws {
    let content = ToDoRecord(id: "one", title: "one", note: "one", dueDate: nil, completed: true)
    let valueRecord = try ValuePayload(content)
    let data = try JSONEncoder().encode(valueRecord)
    let string = try XCTUnwrap(String(data: data, encoding: .utf8))
    let unStringData = try XCTUnwrap(string.data(using: .utf8))
    var decodedRecord = try JSONDecoder().decode(ValuePayload.self, from: unStringData)
    let decodedContent = try decodedRecord.extract(as: ToDoRecord.self)
    XCTAssertEqual(content, decodedContent)
    XCTAssertEqual(valueRecord, decodedRecord)
    XCTAssertEqual(valueRecord.hashValue, decodedRecord.hashValue)
  }

  func test_ValuePayload_repeat_stringIntermediate() async throws {
    let content = ToDoRecord(id: "one", title: "one", note: "one", dueDate: nil, completed: true)
    let valueRecord = try ValuePayload(content)
    let data = try JSONEncoder().encode(valueRecord)
    let string = try XCTUnwrap(String(data: data, encoding: .utf8))
    let unStringData = try XCTUnwrap(string.data(using: .utf8))
    let decodedRecord = try JSONDecoder().decode(ValuePayload.self, from: unStringData)

    let data2 = try JSONEncoder().encode(decodedRecord)
    let string2 = try XCTUnwrap(String(data: data2, encoding: .utf8))
    let unStringData2 = try XCTUnwrap(string2.data(using: .utf8))
    let decodedRecord2 = try JSONDecoder().decode(ValuePayload.self, from: unStringData2)

    let data3 = try JSONEncoder().encode(decodedRecord2)
    let string3 = try XCTUnwrap(String(data: data3, encoding: .utf8))
    let unStringData3 = try XCTUnwrap(string3.data(using: .utf8))
    var decodedRecord3 = try JSONDecoder().decode(ValuePayload.self, from: unStringData3)

    let decodedContent = try decodedRecord3.extract(as: ToDoRecord.self)
    XCTAssertEqual(content, decodedContent)
    XCTAssertEqual(string, string3)
    XCTAssertEqual(valueRecord, decodedRecord3)
    XCTAssertEqual(valueRecord.hashValue, decodedRecord2.hashValue)
  }

}

// MARK: - Wrapper

struct Wrapper<T> {
  var content: T
}

// MARK: Encodable

extension Wrapper: Encodable where T: Encodable { }

// MARK: Decodable

extension Wrapper: Decodable where T: Decodable { }

// MARK: Equatable

extension Wrapper: Equatable where T: Equatable { }

// MARK: Hashable

extension Wrapper: Hashable where T: Hashable { }

// MARK: - SerializationBugTests.ToDoRecord

extension SerializationBugTests {

  struct ToDoRecord: Identifiable, Codable, Hashable {
    struct SubStruct: Codable, Hashable {
      var text: String = "hello"
      var dict: [UUID: String] = [
        UUID(): "one",
        UUID(): "two",
        UUID(): "three",
      ]
    }

    var id: String = UUID().uuidString
    var title: String = ""
    var note: String = ""
    var dueDate: Date?
    var completed: Bool = false

    var list = [UUID(), UUID(), UUID()]
    var set = Set([UUID(), UUID(), UUID()])
    var dict: [UUID: UUID] = [
      UUID(): UUID(),
      UUID(): UUID(),
      UUID(): UUID(),
    ]
    var sub = SubStruct()
    var orderedDict: OrderedDictionary<UUID, String> = [
      UUID(): "one",
      UUID(): "two",
      UUID(): "three",
    ]

    var wrapped = Wrapper(content: 123)
  }

}
