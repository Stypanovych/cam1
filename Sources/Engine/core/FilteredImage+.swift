import Resources
import CoreImage
import UIKit

public extension Resource {
  func ciimage() -> CIImage {
    return CIImage(contentsOf: url)!
  }
  
  func video() -> Video {
    return Video(file: .init(url: url))
  }
}

public extension File.Pointer {
  func ciimage() -> CIImage? {
    return CIImage(contentsOf: url)
  }
}

// Cannot nest in FilteredImage.Parameters due to CasePaths bug
public struct InMemoryResources: Equatable {
  public var lightLeak: CIImage
  public var lookup: CIImage
  public var grain: CIImage
  public var dust: Dust
  
  public struct Dust: Equatable {
    public var particles: InMemoryVideoFrame
    public var hairs: InMemoryVideoFrame
  }
}

extension FilteredImage.Parameters {
//  public struct InMemoryResources: Equatable {
//    public var lightLeak: CIImage
//    public var lookup: CIImage
//    public var grain: CIImage
//    public var dust: Dust
//
//    public struct Dust: Equatable {
//      public var particles: InMemoryVideoFrame
//      public var hairs: InMemoryVideoFrame
//    }
//  }
}

// nesting inside InMemoryResources surfaces weird swift bug
public struct InMemoryVideoFrame: Equatable {
  public var intensity: CGFloat
  public var video: Video
  public var frame: CIImage
  
  init(intensity: CGFloat, video: Video) {
    self.intensity = intensity
    self.video = video
    frame = video[intensity] ?? .black
  }
}

public extension FilteredImage.Parameters {
  func resources() -> InMemoryResources {
    return .init(
      lightLeak: lightLeak.ciimage(),
      lookup: lookup.ciimage(),
      grain: Resources.Grain.overlay.resource.ciimage(),
      dust: .init(
        particles: .init(
          intensity: dustParticleIntensity,
          video: Resources.Dust.particles.resource.video()
        ),
        hairs: .init(
          intensity: dustHairIntensity,
          video: Resources.Dust.hairs.resource.video()
        )
      )
    )
  }
  
  func resources(diffing resources: InMemoryResources) -> InMemoryResources {
    let lightLeak = (resources.lightLeak.url == lightLeak.url)
      ? resources.lightLeak
      : lightLeak.ciimage()
    let lookup = (resources.lookup.url == lookup.url)
      ? resources.lookup
      : lookup.ciimage()
    let particles = resources.dust.particles.intensity == dustParticleIntensity
      ? resources.dust.particles
      : .init(intensity: dustParticleIntensity, video: resources.dust.particles.video)
    let hairs = resources.dust.hairs.intensity == dustHairIntensity
      ? resources.dust.hairs
    : .init(intensity: dustHairIntensity, video: resources.dust.hairs.video)
    return .init(
      lightLeak: lightLeak,
      lookup: lookup,
      grain: resources.grain,
//      dust: 0
      dust: .init(
        particles: particles,
        hairs: hairs
      )
    )
  }
}

extension FilteredImage {
  public struct Factory {
    public let create: (UIImage, FilteredImage.Metadata) throws -> FilteredImage
    public let update: (FilteredImage, FilteredImage.Parameters) throws -> FilteredImage
    public let delete: (FilteredImage) throws -> Void
    
    public static func persistedToDisk(
      filter: @escaping DazeFilter
    ) -> Self {
      func create(from image: UIImage, metadata: FilteredImage.Metadata) throws -> FilteredImage {
        let parameters = FilteredImage.Parameters.random

        let originalImageFile = File.Pointer(directory: .dazecam.originalImage, name: .unique, ext: .jpg)
        let filteredImageFile = File.Pointer(directory: .dazecam.filteredImage, name: .unique, ext: .jpg)
        let thumbnailImageFile = File.Pointer(directory: .dazecam.thumbnailImage, name: .unique, ext: .jpg)

        try autoreleasepool {
          try save(
            originalImage: image,
            metadata: metadata,
            parameters: parameters,
            files: (original: originalImageFile, filtered: filteredImageFile, thumbnail: thumbnailImageFile)
          )
        }
        
        let filteredImage = FilteredImage(
          id: UUID(),
          originalImagePath: originalImageFile,
          filteredImagePath: filteredImageFile,
          thumbnailImagePath: thumbnailImageFile,
          filterDate: Date(),
          metadata: metadata,
          parameters: parameters,
          preset: nil
        )
        return filteredImage
      }
      
      func save(
        originalImage: UIImage,
        metadata: FilteredImage.Metadata,
        parameters: FilteredImage.Parameters,
        files: (original: File.Pointer, filtered: File.Pointer, thumbnail: File.Pointer)
      ) throws {
        let imageData = autoreleasepool { originalImage.normalizeOrientation().jpegData(compressionQuality: 1.0) }
        guard let originalImageData = imageData else { throw GenericError("compression failed") }
        guard let ciimage = CIImage(data: originalImageData) else { throw GenericError("could not create CIImage") }
        let resources = parameters.resources()
        let filteredImageData = try filter(ciimage, metadata, parameters, resources)
          .render(compression: 1.0, renderer: .lowQuality) // high quality fucks up date blend
        let thumbnailImageData = try filter(ciimage, metadata, parameters, resources)
          .filter { size(.fitting(area: 500 * 500)) }
          .render(compression: 1.0, renderer: .lowQuality)
        
        try files.original.file(with: originalImageData).store()
        try files.filtered.file(with: filteredImageData).store()
        try files.thumbnail.file(with: thumbnailImageData).store()
      }
      
      func update(
        _ filteredImage: FilteredImage,
        with parameters: FilteredImage.Parameters
      ) throws -> FilteredImage {
        guard
          let data = filteredImage.originalImagePath.data(),
          let originalImage = UIImage(data: data)
        else { throw GenericError("no data at path") }
        try save(
          originalImage: originalImage,
          metadata: filteredImage.metadata,
          parameters: parameters,
          files: (
            original: filteredImage.originalImagePath,
            filtered: filteredImage.filteredImagePath,
            thumbnail: filteredImage.thumbnailImagePath
          )
        )
        return Engine.update(filteredImage) {
          $0.parameters = parameters
        }
      }
      
      func delete(
        _ filteredImage: FilteredImage
      ) throws {
        try filteredImage.originalImagePath.delete()
        try filteredImage.filteredImagePath.delete()
        try filteredImage.thumbnailImagePath.delete()
      }
      
      return .init(
        create: create,
        update: update,
        delete: delete
      )
    }
  }
}
