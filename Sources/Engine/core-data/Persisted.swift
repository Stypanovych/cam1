import CoreStore
import CoreData
import ComposableArchitecture
import Combine

public struct Persisted<Value> {
  public let fetch: () -> AnyPublisher<Value, Never>
  public let store: (Value) -> AnyPublisher<Void, Never>
}

public extension Persisted {
  static func memory(defaultValue: Value) -> Persisted<Value> {
    var value = defaultValue
    return .init(
      fetch: { Just(value).eraseToAnyPublisher() },
      store: {
        value = $0
        return Empty().eraseToAnyPublisher()
      }
    )
  }
}

extension User: CoreStoreBacked {
  typealias CoreStoreType = CoreStoreUser
  
  static func map(_ object: CoreStoreUser) -> User {
    return .init(
      id: object.id,
      openedApp: object.openedApp,
      viewedReviewPrompt: object.viewedReviewPrompt,
      importsCount: KeychainStorage.shared.importsCount, // retrieve from keychain
      importLimit: object.importLimit,
      images: {
        let sortedImages = object.images
          .map(FilteredImage.map)
          .sorted(by: { $0.filterDate < $1.filterDate })
        return IdentifiedArray(uniqueElements: sortedImages)
      }(),
      presets: {
        let sortedPresets = object.presets
          .map(User.Preset.map)
          .sorted(by: { $0.creationDate > $1.creationDate })
        return IdentifiedArray(uniqueElements: sortedPresets)
      }(),
      purchases: []
    )
  }
  
  /// assumes matching relationships and valid ids
  func sync(_ object: CoreStoreUser) {
    object.importLimit = importLimit
    object.openedApp = openedApp
    KeychainStorage.shared.importsCount = importsCount
    object.viewedReviewPrompt = viewedReviewPrompt
    object.images.forEach { images[id: $0.id]!.sync($0) }
    object.presets.forEach { presets[id: $0.id]!.sync($0) }
  }
}

public extension Persisted where Value == User {
  static func corestore(sqliteFileUrl: URL, bundle: Bundle) -> Self {
    var idDict: [UUID: NSManagedObjectID] = [:]
    var dataStack: DataStack!
    
    return .init(
      fetch: {
        func createDataStack() -> AnyPublisher<Void, Error> {
          guard dataStack == nil else { return Empty().eraseToAnyPublisher() }
          dataStack = v2DataStack(bundle: bundle)
          let store = SQLiteStore(
            fileURL: sqliteFileUrl,
            configuration: "Default",
            migrationMappingProviders: [
              CoreStoreModels.Migrations.legacy_to_v1_mapping,
              CoreStoreModels.Migrations.v1_to_v2_mapping
            ]
          )
          // .reactive.addStorage has progress emitted as values from the publisher
          return Future<SQLiteStore, Error>.deferred { promise in
            let _: Progress? = dataStack.addStorage(store) { result in
              let newResult = result
                .mapError { $0 as Error }
              promise(newResult)
            }
          }
          .map { _ in () }
          .eraseToAnyPublisher()
        }
        func setup(_ coreStoreUser: CoreStoreUser) -> User {
          idDict[coreStoreUser.id] = coreStoreUser.objectID()
          coreStoreUser.images.forEach { idDict[$0.id] = $0.objectID() }
          coreStoreUser.presets.forEach { idDict[$0.id] = $0.objectID() }
          return User.map(coreStoreUser)
        }
        func fetch() -> User? {
          (try? dataStack.fetchOne(From<CoreStoreUser>())).map(setup)
        }
        func createNew() -> AnyPublisher<User, Never> {
          dataStack.reactive.perform { transaction in
            let filteredImages = (try? transaction.fetchAll(From<CoreStoreFilteredImage>())) ?? []
            return update(transaction.create(Into<CoreStoreUser>())) {
              $0.images = Set(filteredImages)
            }
          }
          .compactMap { (user: CoreStoreUser) in dataStack.fetchExisting(user) } // for correct nsobjectids
          .map(setup)
          .replaceError(with: .default)
          .eraseToAnyPublisher()
        }
        return createDataStack()
          .flatMap { _ -> AnyPublisher<User, Error> in
            if let user = fetch() { return Just(user).setFailureType(to: Error.self).eraseToAnyPublisher() }
            return createNew().setFailureType(to: Error.self).eraseToAnyPublisher()
          }
          .replaceError(with: .default)
          .eraseToAnyPublisher()
      },
      store: { user in
        guard let userObjectId = idDict[user.id] else { return Just(()).eraseToAnyPublisher() }
        return dataStack.reactive.perform { (transaction: AsynchronousDataTransaction) in
         // let coreStoreUser = transaction.edit(Into<CoreStoreUser>(), userObjectId)!
          let coreStoreUser: CoreStoreUser = transaction.fetchExisting(userObjectId)!
          
          func diff<T: CoreStoreBacked & Identifiable>(
            object: IdentifiedArrayOf<T>,
            coreStoreObject: Set<T.CoreStoreType>
          ) -> (Set<T.ID>, Set<T.ID>) where T.CoreStoreType: Identifiable, T.ID == T.CoreStoreType.ID {
            let coreStoreIdSet = Set(coreStoreObject.map(\.id))
            let idSet = Set(object.map(\.id))
            return (coreStoreIdSet.subtracting(idSet), idSet.subtracting(coreStoreIdSet))
          }
          //let coreStoreUser = coreStoreObject as! CoreStoreUser
//          let coreStoreImagesIdSet = Set(coreStoreUser.images.map(\.id))
//          let imagesIdSet = Set(user.images.map(\.id))
//
//          let coreStoreImageIdsToDelete = coreStoreImagesIdSet.subtracting(imagesIdSet)
//          let coreStoreImageIdsToCreate = imagesIdSet.subtracting(coreStoreImagesIdSet)
          
          // presets
          let (coreStorePresetIdsToDelete, coreStorePresetIdsToCreate) = diff(object: user.presets, coreStoreObject: coreStoreUser.presets)
          let coreStorePresets: Set<CoreStorePreset> = {
            print("presets: deleting \(coreStorePresetIdsToDelete) \ncreating \(coreStorePresetIdsToCreate)")
            transaction.delete(objectIDs: coreStorePresetIdsToDelete.map { idDict[$0]! })
            let coreStorePresetsToCreate = coreStorePresetIdsToCreate.map { id in
              update(transaction.create(Into<CoreStorePreset>())) {
                // match the id and create all relationships
                $0.id = id
                $0.parameters = transaction.create(Into<CoreStoreFilterParameters>())
                idDict[id] = $0.objectID()
              }
            }
            return coreStoreUser.presets
              .filter { !coreStorePresetIdsToDelete.contains($0.id) }
              .union(coreStorePresetsToCreate)
          }()
          
          //transaction.refreshAndMergeAllObjects() // so that newly created presets are accessible with the edit api
          
          // images
          let (coreStoreImageIdsToDelete, coreStoreImageIdsToCreate) = diff(object: user.images, coreStoreObject: coreStoreUser.images)
          
          let imagesToDelete = coreStoreUser.images
            .filter { coreStoreImageIdsToDelete.contains($0.id) }
            .map(FilteredImage.map)
          
          let coreStoreFilteredImages: Set<CoreStoreFilteredImage> = {
            print("images: deleting \(coreStoreImageIdsToDelete) \ncreating \(coreStoreImageIdsToCreate)")

            transaction.delete(objectIDs: coreStoreImageIdsToDelete.map { idDict[$0]! })
            let coreStoreImagesToCreate = coreStoreImageIdsToCreate.map { id in
              update(transaction.create(Into<CoreStoreFilteredImage>())) {
                $0.id = id
                $0.parameters = transaction.create(Into<CoreStoreFilterParameters>())
                idDict[id] = $0.objectID()
              }
            }
            let coreStoreFilteredImages = coreStoreUser.images
              .filter { !coreStoreImageIdsToDelete.contains($0.id) }
              .union(coreStoreImagesToCreate)
            
            coreStoreFilteredImages
              .compactMap { coreStoreImage -> (CoreStoreFilteredImage, FilteredImage)? in
                user.images[id: coreStoreImage.id].map { (coreStoreImage, $0) }
              }
              .filter { coreStoreImage, image in
                // find images that need a preset change
                coreStoreImage.preset?.id != image.preset?.id
              }
              .forEach { coreStoreImage, image in
                print("corestore user presets: \(coreStoreUser.presets.map(\.name))")
                print("user presets: \(user.presets.map(\.name))")
                guard let preset = image.preset else {
                  coreStoreImage.preset = nil
                  return
                }
                //transaction.id
                // if the transaction has not completed then the newly created preset will not be available through the edit api
                //coreStoreImage.preset = transaction.edit(Into<CoreStorePreset>(), idDict[preset.id]!)!
                coreStoreImage.preset = coreStorePresets.first(where: { $0.id == preset.id })
              }
            
            return coreStoreFilteredImages
          }()

          coreStoreUser.images = coreStoreFilteredImages
          coreStoreUser.presets = coreStorePresets
          user.sync(coreStoreUser) // fuck
          
          func removeStorage() {
            imagesToDelete.forEach {
              try? $0.originalImagePath.delete()
              try? $0.filteredImagePath.delete()
              try? $0.thumbnailImagePath.delete()
            }
          }
          removeStorage()
        }
        .catch { _ in Just(()) }
        .eraseToAnyPublisher()
      }
    )
  }
  
  private static var v2Schema: CoreStoreSchema {
    CoreStoreSchema(
      modelVersion: "v2",
      entities: [
        Entity<CoreStoreModels.V2.User>("User"),
        Entity<CoreStoreModels.V2.FilteredImage>("FilteredImage"),
        Entity<CoreStoreModels.V2.FilterParameters>("FilterParameters"),
        Entity<CoreStoreModels.V2.Preset>("Preset"),
      ],
      versionLock: [
        "FilterParameters": [0x853da70293150428, 0x2f0cb4c0a0c93bb7, 0xa2fa862191ba27f9, 0x7224b3f7f9d12ae3],
        "FilteredImage": [0xf00d78f906f74336, 0x666480253a654771, 0xa38d824054b89602, 0x5daa9c9fb43e4ca1],
        "Preset": [0x1399b0c103584e45, 0x6a9621b15f5a2e74, 0x691ea6410bb04f57, 0x29c428f2e8ef55c2],
        "User": [0x1545af5e2ce17ccc, 0xd0dd6719d1b8cf8b, 0x8af833cb26fa6222, 0x405f788f4620df29]
      ]
    )
  }
  
  static func v2DataStack(bundle: Bundle) -> DataStack {
    return DataStack(
      schemaHistory: SchemaHistory(
        allSchema: legacySchema(bundle: bundle) + [v1Schema] + [v2Schema],
        migrationChain: ["Model v6", "v1", "v2"]
      )
    )
  }
  
  private static var v1Schema: CoreStoreSchema {
    CoreStoreSchema(
      modelVersion: "v1",
      entities: [
        Entity<CoreStoreModels.V1.User>("User"),
        Entity<CoreStoreModels.V1.FilteredImage>("FilteredImage"),
        Entity<CoreStoreModels.V1.FilterParameters>("FilterParameters")
      ],
      versionLock: [
        "FilterParameters": [0x248691f292851612, 0x931759b3ba03f46a, 0xa07b322583ac4e85, 0x17b799efb2ba517c],
        "FilteredImage": [0xb98e0a4d2489c3f9, 0x997e69b8cdd6431f, 0x456451e87e361a12, 0x5c95a9c56999f1c0],
        "User": [0xc0c849cdc98b5274, 0x924098eae0e2efcf, 0x3b415292c316312e, 0xc2fca34f43e58dd0]
      ]
    )
  }
  
  static func v1DataStack(bundle: Bundle) -> DataStack {
    return DataStack(
      schemaHistory: SchemaHistory(
        allSchema: legacySchema(bundle: bundle) + [v1Schema],
        migrationChain: ["Model v6", "v1"]
      )
    )
  }
  
  static func legacySchema(bundle: Bundle) -> [XcodeDataModelSchema] {
    let modelName = "Model"
    return XcodeDataModelSchema.from(
      modelName: modelName, // .xcdatamodeld name
      bundle: bundle,
      migrationChain: ["Model v6"]
    ).allSchema
  }
}
