import XCTest
@testable import Intents

// MARK: - URLEncodedFormTests

final class URLEncodedFormTests: XCTestCase {
  // MARK: Codable

  func testDecode() throws {
    let data = """
      name=Tanner&age=23&pets[]=Zizek&pets[]=Foo&dict[a]=1&dict[b]=2&foos[]=baz&nums[]=3.14
      """

    let user = try URLEncodedFormDecoder().decode(User.self, from: data)
    XCTAssertEqual(user.name, "Tanner")
    XCTAssertEqual(user.age, 23)
    XCTAssertEqual(user.pets.count, 2)
    XCTAssertEqual(user.pets.first, "Zizek")
    XCTAssertEqual(user.pets.last, "Foo")
    XCTAssertEqual(user.dict["a"], 1)
    XCTAssertEqual(user.dict["b"], 2)
    XCTAssertEqual(user.foos[0], .baz)
    XCTAssertEqual(user.nums[0], 3.14)
  }

  func testDecodeCommaSeparatedArray() throws {
    let data = """
      name=Tanner&age=23&pets=Zizek,Foo%2C&dict[a]=1&dict[b]=2&foos=baz&nums=3.14
      """
    let user = try URLEncodedFormDecoder().decode(User.self, from: data)
    XCTAssertEqual(user.name, "Tanner")
    XCTAssertEqual(user.age, 23)
    XCTAssertEqual(user.pets.count, 2)
    XCTAssertEqual(user.pets.first, "Zizek")
    XCTAssertEqual(user.pets.last, "Foo,")
    XCTAssertEqual(user.dict["a"], 1)
    XCTAssertEqual(user.dict["b"], 2)
    XCTAssertEqual(user.foos[0], .baz)
    XCTAssertEqual(user.nums[0], 3.14)
  }

  func testDecodeWithoutArrayBrackets() throws {
    let data = """
      name=Tanner&age=23&pets=Zizek&pets=Foo&dict[a]=1&dict[b]=2&foos=baz&nums=3.14
      """

    let user = try URLEncodedFormDecoder().decode(User.self, from: data)
    XCTAssertEqual(user.name, "Tanner")
    XCTAssertEqual(user.age, 23)
    XCTAssertEqual(user.pets.count, 2)
    XCTAssertEqual(user.pets.first, "Zizek")
    XCTAssertEqual(user.pets.last, "Foo")
    XCTAssertEqual(user.dict["a"], 1)
    XCTAssertEqual(user.dict["b"], 2)
    XCTAssertEqual(user.foos[0], .baz)
    XCTAssertEqual(user.nums[0], 3.14)
  }

  func testDecodeArraysToSingleValueFails() throws {
    let data = """
      name[]=Tanner&age[]=23&pets[]=Zizek&pets[]=Foo&dict[a][]=1&dict[b][]=2&foos[]=baz&nums[]=3.14
      """
    XCTAssertThrowsError(try URLEncodedFormDecoder().decode(User.self, from: data))
  }

  func testDecodeStringWithCommas() throws {
    let data = """
      name=Vapor, Tanner&age=23&pets[]=Zizek&pets[]=Foo&dict[a]=1&dict[b]=2&foos[]=baz&nums[]=3.14
      """
    let user = try URLEncodedFormDecoder().decode(User.self, from: data)
    XCTAssertEqual(user.name, "Vapor, Tanner")
    XCTAssertEqual(user.age, 23)
    XCTAssertEqual(user.pets.count, 2)
    XCTAssertEqual(user.pets.first, "Zizek")
    XCTAssertEqual(user.pets.last, "Foo")
    XCTAssertEqual(user.dict["a"], 1)
    XCTAssertEqual(user.dict["b"], 2)
    XCTAssertEqual(user.foos[0], .baz)
    XCTAssertEqual(user.nums[0], 3.14)
  }

  func testDecodeWithoutFlagsAsBoolFailsWhenBoolIsRequired() throws {
    let decoder = URLEncodedFormDecoder()

    let dataWithBool = """
      name=Tanner&age=23&pets[]=Zizek&pets[]=Foo&dict[a]=1&dict[b]=2&foos[]=baz&nums[]=3.14&isCool=false
      """
    let user = try decoder.decode(User.self, from: dataWithBool)
    XCTAssertEqual(user.name, "Tanner")
    XCTAssertEqual(user.age, 23)
    XCTAssertEqual(user.pets.count, 2)
    XCTAssertEqual(user.pets.first, "Zizek")
    XCTAssertEqual(user.pets.last, "Foo")
    XCTAssertEqual(user.dict["a"], 1)
    XCTAssertEqual(user.dict["b"], 2)
    XCTAssertEqual(user.foos[0], .baz)
    XCTAssertEqual(user.nums[0], 3.14)
    XCTAssertEqual(user.isCool, false)
  }

  func testDecodeIndexedArray() throws {
    struct Test: Decodable {
      let array: [String]
    }

    let data = """
      array[0]=a&array[1]=&array[2]=b&array[3]=
      """
    let test = try URLEncodedFormDecoder().decode(Test.self, from: data)
    XCTAssertEqual(test.array[0], "a")
    XCTAssertEqual(test.array[1], "")
    XCTAssertEqual(test.array[2], "b")
    XCTAssertEqual(test.array[3], "")
  }

  func testDecodeUnindexedArray() throws {
    struct Test: Decodable {
      let array: [String]
    }

    let data = """
      array[]=a&array[]=&array[]=b&array[]=
      """
    let test = try URLEncodedFormDecoder().decode(Test.self, from: data)
    XCTAssertEqual(test.array[0], "a")
    XCTAssertEqual(test.array[1], "")
    XCTAssertEqual(test.array[2], "b")
    XCTAssertEqual(test.array[3], "")
  }

  func testDecodeIndexedArray_dictionary() throws {
    struct Test: Decodable {
      let array: [Int: String]
    }

    let data = """
      array[0]=a&array[1]=b
      """
    let test = try URLEncodedFormDecoder().decode(Test.self, from: data)
    XCTAssertEqual(test.array[0], "a")
    XCTAssertEqual(test.array[1], "b")
  }

  func testDateArrayCoding() throws {
    let toEncode = DateArrayCoding(
      dates: [
        Date(timeIntervalSince1970: 0),
        Date(timeIntervalSince1970: 10000),
        Date(timeIntervalSince1970: 20000),
        Date(timeIntervalSince1970: 30000),
        Date(timeIntervalSince1970: 40000),
        Date(timeIntervalSince1970: 50000),
      ]
    )

    let resultForISOEncoder = try URLEncodedFormEncoder().encode(toEncode)
    XCTAssertEqual(
      "dates=1970-01-01T00:00:00Z,1970-01-01T02:46:40Z,1970-01-01T05:33:20Z,1970-01-01T08:20:00Z,1970-01-01T11:06:40Z,1970-01-01T13:53:20Z",
      resultForISOEncoder
    )

    let decodedInternetDateTime = try URLEncodedFormDecoder()
      .decode(DateArrayCoding.self, from: resultForISOEncoder)
    XCTAssertEqual(decodedInternetDateTime, toEncode)

    XCTAssertThrowsError(
      try URLEncodedFormDecoder()
        .decode(DateArrayCoding.self, from: "dates=bad-date")
    )
  }

  func testDateCoding() throws {
    let toEncode = DateCoding(date: Date(timeIntervalSince1970: 0))

    let resultForInternetDateTime = try URLEncodedFormEncoder().encode(toEncode)
    XCTAssertEqual("date=1970-01-01T00:00:00Z", resultForInternetDateTime)

    let decodedInternetDateTime = try URLEncodedFormDecoder()
      .decode(DateCoding.self, from: resultForInternetDateTime)
    XCTAssertEqual(decodedInternetDateTime, toEncode)

    XCTAssertThrowsError(
      try URLEncodedFormDecoder()
        .decode(DateCoding.self, from: "date=bad-date")
    )
  }

  func testOptionalDateEncodingAndDecoding_GH2518() throws {
    let optionalDate: Date? = Date(timeIntervalSince1970: 0)
    let dateString = "1970-01-01T00:00:00Z"

    let resultForDecodedOptionalDate = try URLEncodedFormDecoder()
      .decode(Date?.self, from: dateString)
    XCTAssertEqual(optionalDate, resultForDecodedOptionalDate)

    let resultForEncodedOptionalDate = try URLEncodedFormEncoder().encode(optionalDate)
    XCTAssertEqual(dateString, resultForEncodedOptionalDate)
  }

  func testEncodeArraySeparator() throws {
    let user = User(
      name: "Tanner",
      age: 23,
      pets: ["Zizek", "Foo"],
      dict: ["a": 1, "b": 2],
      foos: [.baz],
      nums: [3.14],
      isCool: true
    )
    let result = try URLEncodedFormEncoder().encode(user)
    XCTAssert(result.contains("pets=Zizek,Foo"))
    XCTAssert(result.contains("age=23"))
    XCTAssert(result.contains("name=Tanner"))
    XCTAssert(result.contains("dict[a]=1"))
    XCTAssert(result.contains("dict[b]=2"))
    XCTAssert(result.contains("foos=baz"))
    XCTAssert(result.contains("nums=3.14"))
    XCTAssert(result.contains("isCool=true"))
  }

  func testInheritanceCoding() throws {
    let toEncode = ChildClass()
    toEncode.baseField = "Base Value"
    toEncode.childField = "Child Field"
    let result = try URLEncodedFormEncoder().encode(toEncode)
    let decoded = try URLEncodedFormDecoder().decode(ChildClass.self, from: result)
    XCTAssertEqual(decoded, toEncode)
  }

  func testArraysOfArraysOfObjects() throws {
    let toEncode = [[User(
      name: "Tanner",
      age: 23,
      pets: ["Zizek", "Foo"],
      dict: ["a": 1, "b": 2],
      foos: [.baz],
      nums: [3.14],
      isCool: true
    )]]
    let result = try URLEncodedFormEncoder().encode(toEncode)
    let kvs = result.split(separator: "&")
    XCTAssert(kvs.contains("0[0][name]=Tanner"))
    let decoded = try URLEncodedFormDecoder().decode([[User]].self, from: result)
    XCTAssertEqual(decoded, toEncode)
  }

  func testMultiObjectArrayEncodeWithArraySeparator() throws {
    let tanner = User(
      name: "Tanner",
      age: 23,
      pets: ["Zizek", "Foo"],
      dict: ["a": 1, "b": 2],
      foos: [.baz],
      nums: [3.14],
      isCool: true
    )
    let ravneet = User(
      name: "Ravneet",
      age: 33,
      pets: ["Piku"],
      dict: ["a": -3, "b": 99],
      foos: [.baz, .bar],
      nums: [3.14, 144],
      isCool: true
    )
    let usersToEncode = Users(users: [tanner, ravneet])
    let result = try URLEncodedFormEncoder().encode(usersToEncode)
    XCTAssert(result.contains("users[0][pets]=Zizek,Foo"))
    XCTAssert(result.contains("users[0][age]=23"))
    XCTAssert(result.contains("users[0][name]=Tanner"))
    XCTAssert(result.contains("users[0][dict][a]=1"))
    XCTAssert(result.contains("users[0][dict][b]=2"))
    XCTAssert(result.contains("users[0][foos]=baz"))
    XCTAssert(result.contains("users[0][nums]=3.14"))
    XCTAssert(result.contains("users[0][isCool]=true"))

    XCTAssert(result.contains("users[1][pets]=Piku"))
    XCTAssert(result.contains("users[1][age]=33"))
    XCTAssert(result.contains("users[1][name]=Ravneet"))
    XCTAssert(result.contains("users[1][dict][a]=-3"))
    XCTAssert(result.contains("users[1][dict][b]=99"))
    XCTAssert(result.contains("users[1][foos]=baz,bar"))
    XCTAssert(result.contains("users[1][nums]=3.14,144"))
    XCTAssert(result.contains("users[1][isCool]=true"))

    let decodedUsers = try URLEncodedFormDecoder().decode(Users.self, from: result)
    XCTAssertEqual(decodedUsers, usersToEncode)
  }

  ///     func testCodable() throws {
  ///         let a = User(name: "Tanner", age: 23, pets: ["Zizek", "Foo"], dict: ["a": 1, "b": 2], foos: [], nums: [], isCool: true)
  ///         let body = try URLEncodedFormEncoder().encode(a)
  ///         print(body)
  ///         let b = try! URLEncodedFormDecoder().decode(User.self, from: body)
  ///         XCTAssertEqual(a, b)
  ///     }
  ///
  func testDecodeIntArray() throws {
    let data = """
      array[]=1&array[]=2&array[]=3
      """

    let content = try URLEncodedFormDecoder().decode([String: [Int]].self, from: data)
    XCTAssertEqual(content["array"], [1, 2, 3])
  }

  func testRawEnum() throws {
    enum PetType: String, Codable {
      case cat
      case dog
    }
    struct Pet: Codable {
      var name: String
      var type: PetType
    }
    let ziz = try URLEncodedFormDecoder().decode(Pet.self, from: "name=Ziz&type=cat")
    XCTAssertEqual(ziz.name, "Ziz")
    XCTAssertEqual(ziz.type, .cat)
    let string = try URLEncodedFormEncoder().encode(ziz)
    XCTAssertEqual(string.contains("name=Ziz"), true)
    XCTAssertEqual(string.contains("type=cat"), true)
  }

  func testFlagDecodingAsBool() throws {
    struct Foo: Codable {
      var flag: Bool
    }
    let foo = try URLEncodedFormDecoder().decode(Foo.self, from: "flag")
    XCTAssertEqual(foo.flag, true)
  }

  func testFlagIsOnDecodingAsBool() throws {
    struct Foo: Codable {
      var flag: Bool
    }
    let foo = try URLEncodedFormDecoder().decode(Foo.self, from: "flag=on")
    XCTAssertEqual(foo.flag, true)
  }

  /// https://github.com/vapor/url-encoded-form/issues/3
  func testGH3() throws {
    struct Foo: Codable {
      var flag: Bool
    }
    let foo = try URLEncodedFormDecoder().decode(Foo.self, from: "flag=1")
    XCTAssertEqual(foo.flag, true)
  }

  // MARK: Parser

  func testBasic() throws {
    let data = "hello=world&foo=bar"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["hello": "world", "foo": "bar"])
  }

  func testBasicWithAmpersand() throws {
    let data = "hello=world&foo=bar%26bar"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["hello": "world", "foo": "bar&bar"])
  }

  func testDictionary() throws {
    let data = "greeting[en]=hello&greeting[es]=hola"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["greeting": ["es": "hola", "en": "hello"]])
  }

  func testArray() throws {
    let data = "greetings[]=hello&greetings[]=hola"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["greetings": ["": ["hello", "hola"]]])
  }

  func testArrayWithoutBrackets() throws {
    let data = "greetings=hello&greetings=hola"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["greetings": ["hello", "hola"]])
  }

  func testSubArray() throws {
    let data = "greetings[sub][]=hello&greetings[sub][]=hola"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["greetings": ["sub": ["": ["hello", "hola"]]]])
  }

  func testSubArray2() throws {
    let data = "greetings[sub]=hello&greetings[sub][]=hola"
    let form = try URLEncodedFormParser().parse(data)
    let expected: URLEncodedFormData = ["greetings": ["sub":
        URLEncodedFormData(values: ["hello"], children: [
          "": "hola",
        ]),
    ]]
    XCTAssertEqual(form, expected)
  }

  func testSubArray3() throws {
    let data = "greetings[sub][]=hello&greetings[sub]=hola"
    let form = try URLEncodedFormParser().parse(data)
    let expected: URLEncodedFormData = ["greetings": ["sub":
        URLEncodedFormData(values: ["hola"], children: [
          "": "hello",
        ]),
    ]]
    XCTAssertEqual(form, expected)
  }

  func testSubArray4() throws {
    let data = "greetings[sub][]=hello&greetings[sub]=hola&greetings[sub]=bonjour"
    let form = try URLEncodedFormParser().parse(data)
    let expected: URLEncodedFormData = ["greetings": ["sub":
        URLEncodedFormData(values: ["hola", "bonjour"], children: [
          "": "hello",
        ]),
    ]]
    XCTAssertEqual(form, expected)
  }

  func testBracketsInTheMiddle() throws {
    let data = "greetings[sub][][a]=hello&greetings[sub][][a]=hola"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["greetings": ["sub": ["": ["a": ["hello", "hola"]]]]])
  }

  func testSubArrayWithoutBrackets() throws {
    let data = "greetings[sub]=hello&greetings[sub]=hola"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["greetings": ["sub": ["hello", "hola"]]])
  }

  func testFlags() throws {
    let data = "hello=&foo"
    let form = try URLEncodedFormParser().parse(data)
    let expected = URLEncodedFormData(values: ["foo"], children: [
      "hello": URLEncodedFormData(""),
    ])
    XCTAssertEqual(form, expected)
  }

  func testPercentDecoding() throws {
    let data = "aaa%5B%5D=%2Bbbb%20+ccc&d[]=1&d[]=2"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["aaa": ["": "+bbb  ccc"], "d": ["": ["1", "2"]]])
  }

  func testNestedParsing() throws {
    // a[][b]=c&a[][b]=c
    // [a:[[b:c],[b:c]]
    let data = "a[b][c][d][hello]=world"
    let form = try URLEncodedFormParser().parse(data)
    XCTAssertEqual(form, ["a": ["b": ["c": ["d": ["hello": "world"]]]]])
  }

  // MARK: Serializer

  func testPercentEncoding() throws {
    let form: URLEncodedFormData = ["aaa]": "+bbb  ccc"]
    let data = try URLEncodedFormSerializer().serialize(form)
    XCTAssertEqual(data, "aaa%5D=%2Bbbb%20%20ccc")
  }

  func testPercentEncodingWithAmpersand() throws {
    let form: URLEncodedFormData = ["aaa": "b%26&b"]
    let data = try URLEncodedFormSerializer().serialize(form)
    XCTAssertEqual(data, "aaa=b%2526%26b")
  }

  func testNested() throws {
    let form: URLEncodedFormData = ["a": ["b": ["c": ["d": ["hello": "world"]]]]]
    let data = try URLEncodedFormSerializer().serialize(form)
    XCTAssertEqual(data, "a[b][c][d][hello]=world")
  }

  func testPercentEncodingSpecial() throws {
    let data = try URLEncodedFormSerializer().serialize([
      "test": "&;!$'(),/:=?@~",
    ])
    XCTAssertEqual(data, "test=%26%3B!$'(),/:%3D%3F@~")
  }

  func testHeavilyNestedArray() throws {
    var body = "x"
    body += String(repeating: "[]", count: 80000)
    body += "=y"
    struct Foo: Codable { }
    XCTAssertThrowsError(try URLEncodedFormDecoder().decode(Foo.self, from: body))
    XCTAssert(true, "We should not have crashed")
  }
}

// MARK: - User

private struct User: Codable, Equatable {
  var name: String
  var age: Int
  var pets: [String]
  var dict: [String: Int]
  var foos: [Foo]
  var nums: [Decimal]
  var isCool: Bool
}

// MARK: - BaseClass

class BaseClass: Codable, Equatable {
  var baseField: String?

  static func == (lhs: BaseClass, rhs: BaseClass) -> Bool {
    return lhs.baseField == rhs.baseField
  }
}

// MARK: - ChildClass

class ChildClass: BaseClass {
  var childField: String?

  static func == (lhs: ChildClass, rhs: ChildClass) -> Bool {
    return lhs.baseField == rhs.baseField && lhs.childField == rhs.childField
  }
}

// MARK: - Users

private struct Users: Codable, Equatable {
  var users: [User]
}

// MARK: - Foo

private enum Foo: String, Codable {
  case foo
  case bar
  case baz
}

// MARK: - DateCoding

struct DateCoding: Codable, Equatable {
  let date: Date
}

// MARK: - DateArrayCoding

struct DateArrayCoding: Codable, Equatable {
  let dates: [Date]
}

// MARK: - DF

public enum DF {
  static func make() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "'Date:' yyyy-MM-dd 'Time:' HH:mm:ss 'Timezone:' ZZZZZ"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return dateFormatter
  }
}
