import DazeFoundation
import UIKit

public struct Directories {
  public let originalImage: Directory
  public let filteredImage: Directory
  public let thumbnailImage: Directory
  
  public static let live: Self = {
    let images = Directory(name: "images", parent: .documents)
    return .init(
      originalImage: Directory(name: "original", parent: images),
      filteredImage: Directory(name: "processed", parent: images),
      thumbnailImage: Directory(name: "thumbnail", parent: images)
    )
  }()
}

public extension Directory {
  static var dazecam: Directories { .live }
}

// store frames in application support then give app directories
// too long to store -- do it on background thread
//
//public struct DiskResources {
//  public var dust: (_ frameNumber: Int) -> File.Pointer
//}
//
//public extension DiskResources {
//  static func live() -> Self {
//    let dustResource = Resources.Dust.particles.resource
//    let cachedResources = DiskResources(
//      dust: {
//        File.Pointer(
//          directory: Directory(name: dustResource.name, parent: .applicationSupport),
//          name: "\($0)",
//          ext: .png
//        )
//      }
//    )
//    let video = dustResource.video()
//    for frameNumber in 0..<video.frameCount {
//      let filePointer = cachedResources.dust(frameNumber)
//      autoreleasepool {
//        guard
//          !filePointer.hasFile,
//          let cgimage = video[frameNumber],
//          let data = UIImage(cgImage: cgimage).pngData()
//        else { return }
//        try? filePointer.file(with: data).store()
//      }
//    }
//    return cachedResources
//  }
//}
