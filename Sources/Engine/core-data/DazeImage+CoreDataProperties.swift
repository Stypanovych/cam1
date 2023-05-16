import Foundation
import CoreData

extension DazeImage {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<DazeImage> {
    return NSFetchRequest<DazeImage>(entityName: "DazeImage")
  }
  @NSManaged public var originalImagePath: String?
  @NSManaged public var processedImagePath: String?
  @NSManaged public var thumbnailImagePath: String?
  @NSManaged public var date: Date?
  @NSManaged public var parameters: Parameters?
}
