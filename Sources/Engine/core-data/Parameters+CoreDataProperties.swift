import Foundation
import CoreData

extension Parameters {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Parameters> {
      return NSFetchRequest<Parameters>(entityName: "Parameters")
  }
  @NSManaged public var blurRadius: Float
  @NSManaged public var chromaScale: Float
  @NSManaged public var dustOpacity: Float
  @NSManaged public var dustOverlayImageName: String
  @NSManaged public var glowOpacity: Float
  @NSManaged public var glowRadius: Float
  @NSManaged public var glowThreshold: Float
  @NSManaged public var grainOpacity: Float
  @NSManaged public var grainSize: Float
  @NSManaged public var lightLeakOpacity: Float
  @NSManaged public var lightLeakOverlayName: String
  @NSManaged public var lookupImageName: String
  @NSManaged public var lookupIntensity: Float
  @NSManaged public var vignetteIntensity: Float
  @NSManaged public var vignetteOffsetX: Float
  @NSManaged public var vignetteOffsetY: Float
  @NSManaged public var stampDateVisible: Bool
  @NSManaged public var stampTimeVisible: Bool
  @NSManaged public var dazeImage: DazeImage?
}
