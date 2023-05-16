import CoreStore
import DazeFoundation
import Foundation
import Combine
import CoreGraphics
import CoreData

protocol CoreStoreBacked {
  associatedtype CoreStoreType: CoreStoreObject
  static func map(_ object: CoreStoreType) -> Self
  func sync(_ object: CoreStoreType)
}


fileprivate extension GenericError {
  static var doesNotExist: Self { .init("object does not exist") }
  static var alreadyExists: Self { .init("object already exists") }
}

extension DataStack {
  func perform<T>(asynchronous: @escaping (AsynchronousDataTransaction) throws -> T) -> AnyPublisher<T, Error> {
    Future.deferred { promise in
      self.perform(
        asynchronous: asynchronous,
        completion: { promise($0.mapError { $0 as Error }) }
      )
    }
  }
}

typealias CoreStoreUser = CoreStoreModels.V2.User
typealias CoreStoreFilteredImage = CoreStoreModels.V2.FilteredImage
typealias CoreStoreFilterParameters = CoreStoreModels.V2.FilterParameters
typealias CoreStorePreset = CoreStoreModels.V2.Preset

enum CoreStoreModels {
  enum V2 {
    final class User: CoreStoreObject {
      @Field.Stored("id", dynamicInitialValue: { UUID() })
      var id: UUID
      
      @Field.Stored("openedApp")
      var openedApp: Bool = false
      
      @Field.Stored("viewedReviewPrompt")
      var viewedReviewPrompt: Bool = false
      
      @Field.Stored("importLimit")
      var importLimit: Int = 3
      
      @Field.Relationship("images", inverse: \.$user)
      var images: Set<FilteredImage>
      
      @Field.Relationship("presets", inverse: \.$user)
      var presets: Set<Preset>
    }
    
    final class FilteredImage: CoreStoreObject {
      @Field.Stored("id", dynamicInitialValue: { UUID() })
      var id: UUID
      
      @Field.Relationship("user")
      var user: User?
      
      @Field.Stored("originalImagePath")
      var originalImagePath: String = ""
      
      @Field.Stored("processedImagePath")
      var processedImagePath: String = ""
      
      @Field.Stored("thumbnailImagePath")
      var thumbnailImagePath: String = ""
      
      @Field.Stored("originDate", dynamicInitialValue: { Date() })
      var originDate: Date
      
      @Field.Stored("filterDate", dynamicInitialValue: { Date() })
      var filterDate: Date
      
      @Field.Relationship("parameters", inverse: \.$dazeImage)
      var parameters: FilterParameters?
      
      @Field.Relationship("preset", inverse: \.$images)
      var preset: Preset?
    }
    
    final class Preset: CoreStoreObject {
      @Field.Stored("id", dynamicInitialValue: { UUID() })
      var id: UUID
      
      @Field.Stored("name")
      var name: String = ""
      
      @Field.Stored("creationDate", dynamicInitialValue: { Date() })
      var creationDate: Date
      
      @Field.Relationship("parameters", inverse: \.$preset)
      var parameters: FilterParameters?
      
      @Field.Relationship("images")
      var images: Set<FilteredImage>
      
      @Field.Relationship("user")
      var user: User?
    }
    
    final class FilterParameters: CoreStoreObject {
      @Field.Stored("blurRadius")
      var blurRadius: Float = 0
      
      @Field.Stored("chromaScale")
      var chromaScale: Float = 0
      
      @Field.Stored("dustOpacity")
      var dustOpacity: Float = 0
      
      @Field.Stored("dustParticleIntensity")
      var dustParticleIntensity: Float = 0
      
      @Field.Stored("dustHairIntensity")
      var dustHairIntensity: Float = 0
      
      @Field.Stored("glowOpacity")
      var glowOpacity: Float = 0
      
      @Field.Stored("glowRadius")
      var glowRadius: Float = 0
      
      @Field.Stored("glowThreshold")
      var glowThreshold: Float = 0
      
      @Field.Stored("grainOpacity")
      var grainOpacity: Float = 0
      
      @Field.Stored("grainSize")
      var grainSize: Float = 0
      
      @Field.Stored("lightLeakOpacity")
      var lightLeakOpacity: Float = 0
      
      @Field.Stored("lightLeakOverlayName")
      var lightLeakOverlayName: String = ""
      
      @Field.Stored("lookupImageName")
      var lookupImageName: String = ""
      
      @Field.Stored("lookupIntensity")
      var lookupIntensity: Float = 0
      
      @Field.Stored("vignetteIntensity")
      var vignetteIntensity: Float = 0

      @Field.Stored("stampFont")
      var stampFont: String = StampFont.digital.rawValue
      
      @Field.Stored("stampColor")
      var stampColor: Float = 0
      
      @Field.Stored("stampDateVisible")
      var stampDateVisible: Bool = false
      
      @Field.Stored("stampTimeVisible")
      var stampTimeVisible: Bool = false
      
      @Field.Relationship("dazeImage")
      var dazeImage: FilteredImage?
      
      @Field.Relationship("preset")
      var preset: Preset?
    }
  }
  
  enum V1 {
    final class User: CoreStoreObject {
      @Field.Stored("id", dynamicInitialValue: { UUID() })
      var id: UUID
      
      @Field.Stored("openedApp")
      var openedApp: Bool = false
      
      @Field.Stored("viewedReviewPrompt")
      var viewedReviewPrompt: Bool = false
      
      @Field.Stored("importLimit")
      var importLimit: Int = 3
      
      @Field.Relationship("images", inverse: \.$user)
      var images: Set<FilteredImage>
    }
    
    final class FilteredImage: CoreStoreObject {
      @Field.Stored("id", dynamicInitialValue: { UUID() })
      var id: UUID
      
      @Field.Relationship("user")
      var user: User?
      
      @Field.Stored("originalImagePath")
      var originalImagePath: String = ""
      
      @Field.Stored("processedImagePath")
      var processedImagePath: String = ""
      
      @Field.Stored("thumbnailImagePath")
      var thumbnailImagePath: String = ""
      
      @Field.Stored("originDate", dynamicInitialValue: { Date() })
      var originDate: Date
      
      @Field.Stored("filterDate", dynamicInitialValue: { Date() })
      var filterDate: Date
      
      @Field.Relationship("parameters", inverse: \.$dazeImage)
      var parameters: FilterParameters?
    }
    
    final class FilterParameters: CoreStoreObject {
      @Field.Stored("blurRadius")
      var blurRadius: Float = 0
      
      @Field.Stored("chromaScale")
      var chromaScale: Float = 0
      
      @Field.Stored("dustOpacity")
      var dustOpacity: Float = 0
      
      @Field.Stored("dustParticleIntensity")
      var dustParticleIntensity: Float = 0
      
      @Field.Stored("dustHairIntensity")
      var dustHairIntensity: Float = 0
      
      @Field.Stored("glowOpacity")
      var glowOpacity: Float = 0
      
      @Field.Stored("glowRadius")
      var glowRadius: Float = 0
      
      @Field.Stored("glowThreshold")
      var glowThreshold: Float = 0
      
      @Field.Stored("grainOpacity")
      var grainOpacity: Float = 0
      
      @Field.Stored("grainSize")
      var grainSize: Float = 0
      
      @Field.Stored("lightLeakOpacity")
      var lightLeakOpacity: Float = 0
      
      @Field.Stored("lightLeakOverlayName")
      var lightLeakOverlayName: String = ""
      
      @Field.Stored("lookupImageName")
      var lookupImageName: String = ""
      
      @Field.Stored("lookupIntensity")
      var lookupIntensity: Float = 0
      
      @Field.Stored("vignetteIntensity")
      var vignetteIntensity: Float = 0
      
//      @Field.Stored("vignetteOffsetX")
//      var vignetteOffsetX: Float = 0
//
//      @Field.Stored("vignetteOffsetY")
//      var vignetteOffsetY: Float = 0
      @Field.Stored("stampFont")
      var stampFont: String = StampFont.digital.rawValue
      
      @Field.Stored("stampColor")
      var stampColor: Float = 0
      
      @Field.Stored("stampDateVisible")
      var stampDateVisible: Bool = false
      
      @Field.Stored("stampTimeVisible")
      var stampTimeVisible: Bool = false
      
      @Field.Relationship("dazeImage")
      var dazeImage: FilteredImage?
    }
  }
}

extension CoreStoreModels {
  enum Migrations {
    static var v1_to_v2_mapping: SchemaMappingProvider {
      CustomSchemaMappingProvider(
        from: "v1",
        to: "v2",
        entityMappings: [
          .insertEntity(destinationEntity: "Preset")
        ]
      )
    }
    
    static var legacy_to_v1_mapping: SchemaMappingProvider {
      CustomSchemaMappingProvider(
        from: "Model v6",
        to: "v1",
        entityMappings: [
          //.insertEntity(destinationEntity: "User"),
          .transformEntity(
            sourceEntity: "DazeImage",
            destinationEntity: "FilteredImage",
            transformer: { (sourceObject, createDestinationObject) in
              let destinationObject = createDestinationObject()
              destinationObject["id"] = UUID().uuidString
              //destinationObject["user"] = nil
              destinationObject["originalImagePath"] = sourceObject["originalImagePath"]
              destinationObject["processedImagePath"] = sourceObject["processedImagePath"]
              destinationObject["thumbnailImagePath"] = sourceObject["thumbnailImagePath"]
              let date = sourceObject["date"] ?? Date()
              destinationObject["originDate"] = date
              destinationObject["filterDate"] = date
            }
          ),
          .transformEntity(
            sourceEntity: "Parameters",
            destinationEntity: "FilterParameters",
            transformer: { (sourceObject, createDestinationObject) in
              func normalize(_ value: Any?, _ range: ClosedRange<Float>) -> Float {
                return ((value as! Float) - range.lowerBound) / (range.upperBound - range.lowerBound)
              }
              
              let destinationObject = createDestinationObject()
              //destinationObject["id"] = UUID()
              destinationObject["blurRadius"] = normalize(sourceObject["blurRadius"], 0...5)
              destinationObject["chromaScale"] = normalize(sourceObject["chromaScale"], 0...0.025)
              destinationObject["dustOpacity"] = sourceObject["dustOpacity"]
              
              let dustIntensity: CGFloat = {
                switch (sourceObject["dustOverlayImageName"] as? String) ?? "" {
                case "dust1.jpg": return 0.1
                case "dust2.jpg": return 0.2
                case "dust3.jpg": return 0.3
                default: return 0
                }
              }()
              destinationObject["dustParticleIntensity"] = dustIntensity
              destinationObject["dustHairIntensity"] = dustIntensity

              destinationObject["glowOpacity"] = sourceObject["glowOpacity"]
              destinationObject["glowRadius"] = normalize(sourceObject["glowRadius"], 0...250)
              destinationObject["glowThreshold"] = sourceObject["glowThreshold"]
              destinationObject["grainOpacity"] = sourceObject["grainOpacity"]
//              destinationObject["grainSize"] = normalize(sourceObject["grainSize"], 0.25...1)
              destinationObject["grainSize"] = {
                let grainSize = (sourceObject["grainSize"] as! Float)
                return grainSize == 0 ? 0 : (1 / grainSize - 1)
              }()
              destinationObject["lightLeakOpacity"] = sourceObject["lightLeakOpacity"]
              destinationObject["lightLeakOverlayName"] = sourceObject["lightLeakOverlayName"]
              destinationObject["lookupImageName"] = sourceObject["lookupImageName"]
              destinationObject["lookupIntensity"] = sourceObject["lookupIntensity"]
              destinationObject["vignetteIntensity"] = {
                let vignetteIntensity = sourceObject["vignetteIntensity"] as! Float
                return (vignetteIntensity * 1.3).clamped(by: 0...1)
              }()
//              destinationObject["vignetteOffsetX"] = sourceObject["vignetteOffsetX"]
//              destinationObject["vignetteOffsetY"] = sourceObject["vignetteOffsetY"]
              destinationObject["stampColor"] = 0.8
              destinationObject["stampDateVisible"] = sourceObject["stampDateVisible"]
              destinationObject["stampTimeVisible"] = sourceObject["stampTimeVisible"]
            }
          ),
          .insertEntity(destinationEntity: "User")
        ]
      )
    }
  }
}
