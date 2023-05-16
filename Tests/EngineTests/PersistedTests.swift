import XCTest
import CoreStore
import TestHelpers
import DazeFoundation
import Combine
@testable import Engine

class PersistedTests: XCTestCase {
  // probably other files are being created that also need to be deleted
  var sqliteUrl: URL!
  
  override func setUp() {
    let sqliteBundleFileUrl = Bundle.module.url(forResource: "Model", withExtension: "sqlite")!
    let sqliteContainerFile = File.Pointer(directory: .applicationSupport, name: "Model", ext: "sqlite")
    try? sqliteContainerFile.delete() // if there's already one there
    try! File.Pointer(url: sqliteBundleFileUrl).move(to: sqliteContainerFile)
    sqliteUrl = sqliteContainerFile.url
  }
  
  override func tearDown() {
    try? File.Pointer(url: sqliteUrl).delete()
  }
  
  // run test_model twice then this works idk why
  func test_Persisted() {
    let persisted = Persisted<User>.corestore(
      sqliteFileUrl: sqliteUrl,
      bundle: .module
    )
    print(try! awaitPublisher(persisted.fetch()))
   // print(try! awaitPublisher(createDataStack()))
  }
  
//  func test_model() {
//    let sqliteFileUrl = moveModel()
//    print(sqliteFileUrl)
//    let dataStack = DataStack(xcodeModelName: "Model", bundle: .module)
//    let storage = SQLiteStore(fileURL: sqliteFileUrl)
//    try! dataStack.addStorageAndWait(storage)
//    let elements = try! dataStack.fetchAll(From<DazeImage>(nil))
//    print(elements.count)
//  }
  
  func test_model() {
    let sqliteFileUrl = sqliteUrl!
    print(sqliteFileUrl)
    let dataStack = DataStack(xcodeModelName: "Model", bundle: .module)
    let storage = SQLiteStore(fileURL: sqliteFileUrl)
    try! dataStack.addStorageAndWait(storage)
    let elements = try! dataStack.fetchAll(From<DazeImage>(nil))
    print(elements.count)
  }
}
