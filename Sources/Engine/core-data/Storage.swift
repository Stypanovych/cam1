import UIKit
import CoreData
import Combine
import CoreStore

//public struct Storage<T> {
//  public struct Store {
//    public let fetch: () throws -> [T]
//    public let update: (_ new: T, _ old: T) -> AnyPublisher<Void, Error>
//    public let delete: (T) -> AnyPublisher<Void, Error>
//    public let save: (T) -> AnyPublisher<Void, Error>
//  }
//
//  public let setup: () -> AnyPublisher<Store, Error>
//}
//
//extension Storage where T == FilteredImage {
//  public static var coredata: Self {
//    .init {
//      //let sqliteFile = File.Pointer(directory: .documents, name: "Model", ext: "sqlite")
//      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//      let sqliteFileUrl = documentsPath.appendingPathComponent("Model.sqlite")
//      //let sqliteFileUrl = documentsPath.appendingPathComponent("totallywrong")
//
//      let dataStack = DataStack(
//        xcodeModelName: "Model"
//        //bundle: .main,
//        //migrationChain: ["Model v6"]
//      )
//      let storage = SQLiteStore(
//        fileURL: sqliteFileUrl
//       // configuration: "Default",
//       // migrationMappingProviders: [],
//        //localStorageOptions: .none
//      )
//      let localStorage: LocalStorage = try! dataStack.addStorageAndWait(storage)
//      //CoreStoreDefaults.dataStack = dataStack
//      let store = Storage<FilteredImage>.Store(
//        fetch: {
//          //From<DazeImage>("DazeImage")
//          return try dataStack.fetchAll(From<DazeImage>(nil)).compactMap {
//            return FilteredImage(dazeImage: $0)
//          }
//        },
//        update: { _, _ in Empty().eraseToAnyPublisher()},
//        delete: { _ in Empty().eraseToAnyPublisher() },
//        save: { _ in Empty().eraseToAnyPublisher() }
//      )
//      return .init(Just(store).setFailureType(to: Error.self).eraseToAnyPublisher())
//    }
//  }
//  
//  public static var live: Self {
//    var imageDict: [FilteredImage: DazeImage] = [:]
//    return .init {
//      let store = Storage<FilteredImage>.Store(
//        fetch: {
//          let dazeImages: [DazeImage] = (try? CoreDataManager.shared.fetch()) ?? []
//          //let dazeImages: [DazeImage] = Test().fetch()
//          let tuples = dazeImages.compactMap { dazeImage in
//            FilteredImage(dazeImage: dazeImage).map { ($0, dazeImage) }
//          }
//          imageDict = .init(uniqueKeysWithValues: tuples)
//          return tuples.map { $0.0 }
//        },
//        update: { _, _ in Empty().eraseToAnyPublisher()},
//        delete: { _ in Empty().eraseToAnyPublisher() },
//        save: { _ in Empty().eraseToAnyPublisher() }
//      )
//      return .init(Just(store).setFailureType(to: Error.self).eraseToAnyPublisher())
//    }
//  }
//}

//extension Storage where T == FilteredImage {
//  public static let live: Self = {
//    var imageDict: [FilteredImage: DazeImage] = [:]
//    return .init(
//      fetch: {
//        let dazeImages: [DazeImage] = (try? CoreDataManager.shared.fetch()) ?? []
//        let tuples = dazeImages.compactMap { dazeImage in
//          FilteredImage(dazeImage: dazeImage).map { ($0, dazeImage) }
//        }
//        imageDict = .init(uniqueKeysWithValues: tuples)
//        return tuples.map { $0.0 }
//      },
//      save: { filteredImage in
//        let dazeImage = DazeImage(context: CoreDataManager.shared.context)
//        dazeImage.sync(with: filteredImage)
//        imageDict[filteredImage] = dazeImage
//        //imageDict[filteredImage]?.sync(with: filteredImage)
//        CoreDataManager.shared.save()
//      }
//  //    update: ,
//  //    delete:
//    )
//  }()
//}

//extension DazeImage {
//  func sync(with filteredImage: FilteredImage) {
//    originalImagePath = filteredImage.originalImagePath.removingParent(directory: .documents).path
//    processedImagePath = filteredImage.filteredImagePath.removingParent(directory: .documents).path
//    thumbnailImagePath = filteredImage.thumbnailImagePath.removingParent(directory: .documents).path
//    parameters?.blurRadius = Float(filteredImage.parameters.blurRadius)
//    parameters?.chromaScale = Float(filteredImage.parameters.chromaScale)
//    parameters?.dustOpacity = Float(filteredImage.parameters.dustOpacity)
//    parameters?.dustOverlayImageName = filteredImage.parameters.dustOverlayImageName
//    parameters?.glowOpacity = Float(filteredImage.parameters.glowOpacity)
//    parameters?.glowRadius = Float(filteredImage.parameters.glowRadius)
//    parameters?.glowThreshold = Float(filteredImage.parameters.glowThreshold)
//    parameters?.grainOpacity = Float(filteredImage.parameters.grainOpacity)
//    parameters?.grainSize = Float(filteredImage.parameters.grainSize)
//    parameters?.lightLeakOpacity = Float(filteredImage.parameters.lightLeakOpacity)
//    parameters?.lightLeakOverlayName = filteredImage.parameters.lightLeakOverlayName.name
//    parameters?.lookupImageName = filteredImage.parameters.lookupImageName.name
//    parameters?.lookupIntensity = Float(filteredImage.parameters.lookupIntensity)
//    parameters?.vignetteIntensity = Float(filteredImage.parameters.vignetteIntensity)
//    parameters?.vignetteOffsetX = Float(filteredImage.parameters.vignetteOffsetX)
//    parameters?.vignetteOffsetY = Float(filteredImage.parameters.vignetteOffsetY)
//    parameters?.stampDateVisible = filteredImage.parameters.stampDateVisible
//    parameters?.stampTimeVisible = filteredImage.parameters.stampTimeVisible
//  }
//}

final class CoreDataManager {
  static let shared = CoreDataManager()
  private init() {}
  
  private let moduleName = "Model"
  private(set) lazy var context = persistentContainer.viewContext

  lazy private var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: moduleName)
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: container.managedObjectModel)
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let persistentStoreURL = documentsPath.appendingPathComponent("\(moduleName).sqlite")

    do {
      try coordinator.addPersistentStore(
        ofType: NSSQLiteStoreType,
        configurationName: nil,
        at: persistentStoreURL,
        options: [
          NSMigratePersistentStoresAutomaticallyOption: true,
          NSInferMappingModelAutomaticallyOption: true
        ]
      )
    } catch {
      fatalError("core data error \(error)")
    }

    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()
  
  // MARK: - Core Data Saving support
  
  func saveContext () {
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
  
  private func fetch<T: NSManagedObject>(_ type: T.Type) throws -> [T]  {
    let entityName = String(describing: T.self)
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)

    let fetchedObjects = try context.fetch(fetchRequest) as? [T] ?? [T]()
    return fetchedObjects
  }
}

extension CoreDataManager {
  func fetch<T: NSManagedObject>() throws -> [T] {
    return try fetch(T.self)
  }
  
  func save() {
    saveContext()
  }
  
  func delete<T: NSManagedObject>(_ object: T) {
    context.delete(object)
    saveContext()
  }
}

//class Test {
//
//  func fetch() -> [DazeImage] {
//    let container = NSPersistentContainer(name: "Model")
//    let context = container.viewContext
//    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: container.managedObjectModel)
//
//    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    let persistentStoreURL = documentsPath.appendingPathComponent("Model.sqlite")
//
//    let persistentStore = try! coordinator.addPersistentStore(
//      ofType: NSSQLiteStoreType,
//      configurationName: nil,
//      at: persistentStoreURL,
//      options: [:]
//    )
//    print(persistentStore.url)
//
//    container.loadPersistentStores { _, _ in }
//
//    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DazeImage")
//    return try! context.fetch(fetchRequest) as! [DazeImage]
//  }
//
//  func anotherTest() -> [DazeImage] {
//    let dataStack = DataStack(xcodeModelName: "Model")
//
//    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    let sqliteFileUrl = documentsPath.appendingPathComponent("Model.sqlite")
//
//    let storage = SQLiteStore(fileURL: sqliteFileUrl)
//    print(storage.fileURL)
//    try! dataStack.addStorageAndWait(storage)
//
//    return try! dataStack.fetchAll(From<DazeImage>(nil))
//  }
//}

// file:///var/mobile/Containers/Data/Application/A2C2D3F8-D7F8-4C45-8A97-D8D7742CA168/Documents/Model.sqlite
// file:///var/mobile/Containers/Data/Application/BD908895-17A1-4FEB-9B36-9751C5332DFF/Documents/Model.sqlite

//extension CoreDataManager {
//  func save(_ dazeImageMOP: DazeImageMOP) {
//    dazeImageMOP.sync()
//  }
//
//  func getDazeImageMOPs() throws -> [DazeImageMOP] {
//    let dazeImages = try getDazeImages()
//    let mops = dazeImages.map { (dazeImage) -> DazeImageMOP in
//      return DazeImageMOP(dazeImage)
//    }
//    return mops
//  }
//
//  func update(_ dazeImageMOPs: [DazeImageMOP]) {
//    dazeImageMOPs.forEach { (mop) in
//      mop.sync()
//    }
//  }
//
//  func delete(_ dazeImageMOP: DazeImageMOP) {
//    delete(dazeImage: dazeImageMOP.sync())
//  }
//}

extension CoreDataManager {
  enum DataError: Error {
    case fetchError
    case storeError
  }
}
