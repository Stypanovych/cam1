import XCTest
@testable import DazeFoundation

struct Model: Codable, Default {
  var string: String
  var int: Int
  
  static var `default`: Model { .init(string: "test", int: 6) }
}

final class PersistenceTests: XCTestCase {
  func testPersistence() {
    let persistentModel1 = Persistent<Model>()
      .assign(storage: .memory, key: "string", to: \.string)
      .assign(storage: .memory, key: "int", to: \.int)
    
    XCTAssertEqual(try! persistentModel1.read(\.string), "test")
    XCTAssertEqual(try! persistentModel1.read(\.int), 6)
    
    let model1 = try! persistentModel1.write(\.string, value: "new")
    XCTAssertEqual(model1.string, "new")
    XCTAssertEqual(model1.int, 6)
    
    XCTAssertEqual(try! persistentModel1.read(\.string), "new")
    XCTAssertEqual(try! persistentModel1.read(\.int), 6)
    
    let _ = try! persistentModel1.write(\.int, value: 10)
    
    let persistentModel2 = Persistent<Model>()
      .assign(storage: .memory, key: "string", to: \.string)
      .assign(storage: .memory, key: "int", to: \.int)
    
    XCTAssertEqual(try! persistentModel2.read(\.string), "new")
    XCTAssertEqual(try! persistentModel2.read(\.int), 10)
  }
}
