//import XCTest
//import CoreStore
//import TestHelpers
//@testable import Engine
//
//struct DomainModel: Hashable & CoreStoreBacked {
//  typealias CoreStoreType = CoreStoreModel
//  
//  static func map(_ object: CoreStoreType) -> DomainModel {
//    .init(id: object.id)
//  }
//  
//  func sync(_ object: CoreStoreType) {
//    object.id = id
//  }
//  
//  let id: String
//}
//
//final class CoreStoreModel: CoreStoreObject {
//  @Field.Stored("id")
//  var id: String = ""
//}
//
//final class StorageTests: XCTestCase {
//  func test_storage() {
//    let schema = CoreStoreSchema(
//      modelVersion: "v1",
//      entities: [
//        Entity<CoreStoreModel>("CoreStoreModel")
//      ]
//    )
//    let schemaHistory = SchemaHistory(schema, migrationChain: ["v1"])
//    let dataStack = DataStack(schemaHistory: schemaHistory)
//    try! dataStack.addStorageAndWait(InMemoryStore())
//    
//    let store = Storage<DomainModel>.Store.corestore(dataStack: dataStack)
//    
//    func fetch() throws -> [DomainModel] {
//      return try store.fetch().sorted(by: { $0.id < $1.id })
//    }
//    
//    XCTAssertEqual(try store.fetch(), [])
//    
//    let element1 = DomainModel(id: "id1")
//    try! awaitPublisher(store.save(element1))
//    XCTAssertEqual(try fetch(), [element1])
//    
//    let element2 = DomainModel(id: "id2")
//    try! awaitPublisher(store.save(element2))
//    XCTAssertEqual(try fetch(), [element1, element2])
//    
//    let element3 = DomainModel(id: "id3")
//    try! awaitPublisher(store.update(element3, element1))
//    XCTAssertEqual(try fetch(), [element2, element3])
//    
//    try! awaitPublisher(store.save(element1))
//    XCTAssertEqual(try fetch(), [element1, element2, element3])
//    
//    try! awaitPublisher(store.delete(element2))
//    XCTAssertEqual(try fetch(), [element1, element3])
//    
//    XCTAssertThrowsError(try awaitPublisher(store.delete(element2)))
//    XCTAssertThrowsError(try awaitPublisher(store.save(element1)))
//  }
//  
//  func test_legacy_to_v1_migration() {
//    let sqliteFileUrl = moveModel()
//    let storage = Storage.corestore(sqliteFileUrl: sqliteFileUrl, bundle: .module)
//    let store = try! awaitPublisher(storage.setup())
//    
//    let elements = try! store.fetch()
//    print(elements.map { $0.filterDate })
//  }
//  
//  func test_model() {
//    let sqliteFileUrl = moveModel()
//    print(sqliteFileUrl)
//    let dataStack = DataStack(xcodeModelName: "Model", bundle: .module)
//    let storage = SQLiteStore(fileURL: sqliteFileUrl)
//    try! dataStack.addStorageAndWait(storage)
//    let elements = try! dataStack.fetchAll(From<DazeImage>(nil))
//    print(elements.count)
//  }
//  
//  func moveModel() -> URL {
//    let sqliteBundleFileUrl = File.Pointer(url: Bundle.module.url(forResource: "Model", withExtension: "sqlite")!)
//    let sqliteContainerFile = File.Pointer(directory: .applicationSupport, name: "Model", ext: "sqlite")
//    print(sqliteBundleFileUrl.hasFile)
//    try? sqliteContainerFile.delete() // if there's already one there
//    try! sqliteBundleFileUrl.move(to: sqliteContainerFile)
//    return sqliteContainerFile.url
//  }
//}
//
//extension URL {
//  var attributes: [FileAttributeKey : Any]? {
//    do {
//      return try FileManager.default.attributesOfItem(atPath: path)
//    } catch let error as NSError {
//      print("FileAttribute error: \(error)")
//    }
//    return nil
//  }
//  
//  var fileSize: UInt64 {
//    return attributes?[.size] as? UInt64 ?? UInt64(0)
//  }
//  
//  var fileSizeString: String {
//    return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
//  }
//  
//  var creationDate: Date? {
//    return attributes?[.creationDate] as? Date
//  }
//}
