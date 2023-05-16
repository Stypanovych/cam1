import Foundation
import CoreStore
import CoreGraphics
import Resources

extension CoreStoreFilteredImage: Identifiable {}

extension FilteredImage: CoreStoreBacked {
  typealias CoreStoreType = CoreStoreFilteredImage
  
  static func map(_ object: CoreStoreFilteredImage) -> FilteredImage {
    return .init(
      id: object.id,
      originalImagePath: File.Pointer(path: object.originalImagePath).addingParent(directory: .documents),
      filteredImagePath: File.Pointer(path: object.processedImagePath).addingParent(directory: .documents),
      thumbnailImagePath: File.Pointer(path: object.thumbnailImagePath).addingParent(directory: .documents),
      filterDate: object.filterDate,
      metadata: .init(originDate: object.originDate),
      parameters: FilteredImage.Parameters.map(object.parameters!),
      preset: object.preset.map { User.Preset.map($0) }
    )
  }
  
  func sync(_ object: CoreStoreFilteredImage) {
    object.id = id
    object.originalImagePath = originalImagePath.removingParent(directory: .documents).path
    object.processedImagePath = filteredImagePath.removingParent(directory: .documents).path
    object.thumbnailImagePath = thumbnailImagePath.removingParent(directory: .documents).path
    object.filterDate = filterDate
    object.originDate = metadata.originDate
    //(preset == nil) ? object.preset = nil : preset!.sync(object.preset!)
    //if preset == nil { object.preset = nil } // if not nil then preset will have already been set
    parameters.sync(object.parameters!)
  }
}
