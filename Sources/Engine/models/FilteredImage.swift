import Foundation
import Resources
import CoreGraphics
import DazeFoundation
import CoreImage
import ImageProcessor
import UIKit

public struct FilteredImage: Hashable {
  public let id: UUID
  
  public let originalImagePath: File.Pointer
  public let filteredImagePath: File.Pointer
  public let thumbnailImagePath: File.Pointer
  public let filterDate: Date
  public let metadata: Metadata
  public var parameters: Parameters
  public var preset: User.Preset?
  
  public init(
    id: UUID,
    originalImagePath: File.Pointer,
    filteredImagePath: File.Pointer,
    thumbnailImagePath: File.Pointer,
    filterDate: Date,
    metadata: Metadata,
    parameters: Parameters,
    preset: User.Preset?
  ) {
    self.id = id
    self.originalImagePath = originalImagePath
    self.filteredImagePath = filteredImagePath
    self.thumbnailImagePath = thumbnailImagePath
    self.filterDate = filterDate
    self.metadata = metadata
    self.parameters = parameters
    self.preset = preset
  }
}

extension FilteredImage: Equatable {
  // less computationally expensive than synthesized
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id &&
    lhs.parameters == rhs.parameters
  }
}

public extension FilteredImage {
  struct Metadata: Hashable {
    public let originDate: Date
    
    public init(originDate: Date) {
      self.originDate = originDate
    }
  }
}

//public typealias Parameters = FilteredImage.Parameters

public extension FilteredImage {
  struct Parameters: Hashable {
    public var blurRadius: CGFloat
    public var chromaScale: CGFloat
    public var dustOpacity: CGFloat
    public var dustParticleIntensity: CGFloat
    public var dustHairIntensity: CGFloat
    public var glowOpacity: CGFloat
    public var glowRadius: CGFloat
    public var glowThreshold: CGFloat
    public var grainOpacity: CGFloat
    public var grainSize: CGFloat
    public var lightLeakOpacity: CGFloat
    //public var lightLeakOverlayName: Image { images.lightLeak }
    //public var lookupImageName: Image { images.lookup }
    public var lightLeak: Resource
    public var lookup: Resource
    
    public var lookupIntensity: CGFloat
    public var vignetteIntensity: CGFloat
//    public var vignetteOffsetX: CGFloat
//    public var vignetteOffsetY: CGFloat
    public var stampFont: StampFont
    public var stampColor: CGFloat
    public var stampDateVisible: Bool
    public var stampTimeVisible: Bool
  }
}

public enum StampFont: String {
  case digital
  case dot
  
  public var uiFont: UIFont {
    switch self {
    case .digital: return Theme.Font.Digital().uiFont
    case .dot: return Theme.Font.Dot().uiFont
    }
  }
  
  public static var all: [StampFont] {
    [.digital, .dot]
  }
}

//extension FilteredImage {
//  init?(dazeImage: DazeImage) {
//    guard
//      let originalImagePath = dazeImage.originalImagePath,
//      let processedImagePath = dazeImage.processedImagePath,
//      let thumbnailImagePath = dazeImage.thumbnailImagePath,
//      let parameters = dazeImage.parameters,
//      let date = dazeImage.date
//    else { return nil }
//    self.originalImagePath = File.Pointer(path: originalImagePath).addingParent(directory: .documents)
//    self.filteredImagePath = File.Pointer(path: processedImagePath).addingParent(directory: .documents)
//    self.thumbnailImagePath = File.Pointer(path: thumbnailImagePath).addingParent(directory: .documents)
//    self.parameters = .init(
//      blurRadius: CGFloat(parameters.blurRadius),
//      chromaScale: CGFloat(parameters.chromaScale),
//      dustOpacity: CGFloat(parameters.dustOpacity),
//      dustParticleIntensity: parameters.dustParticleIntensity,
//      glowOpacity: CGFloat(parameters.glowOpacity),
//      glowRadius: CGFloat(parameters.glowRadius),
//      glowThreshold: CGFloat(parameters.glowThreshold),
//      grainOpacity: CGFloat(parameters.grainOpacity),
//      grainSize: CGFloat(parameters.grainSize),
//      lightLeakOpacity: CGFloat(parameters.lightLeakOpacity),
//      //lightLeakOverlayName: Resources.Leak.resource(for: parameters.lightLeakOverlayName),
//      //lookupImageName: Resources.Lut.resource(for: parameters.lookupImageName),
//      lookupIntensity: CGFloat(parameters.lookupIntensity),
//      vignetteIntensity: CGFloat(parameters.vignetteIntensity),
//      vignetteOffsetX: CGFloat(parameters.vignetteOffsetX),
//      vignetteOffsetY: CGFloat(parameters.vignetteOffsetY),
//      stampDateVisible: parameters.stampDateVisible,
//      stampTimeVisible: parameters.stampTimeVisible,
//      images: .init(
//        lightLeak: Resources.Leak.named(parameters.lightLeakOverlayName).resource,
//        lookup: Resources.Lut.named(parameters.lookupImageName).resource
//      )
//    )
//    self.date = date
//  }
//}

public extension FilteredImage.Parameters {
  static var jtree: Self {
    .init(
      blurRadius: 0.25,
      chromaScale: 0.5,
      dustOpacity: (Int.random(in: 0...3) == 0) ? 1 : 0,
      dustParticleIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      dustHairIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      glowOpacity: 0.3,
      glowRadius: 0.25,
      glowThreshold: 0,
      grainOpacity: CGFloat.normal(m: 0.9, v: 0.1).clamped(by: 0.8...1.0),
      grainSize: CGFloat.normal(m: 0.2, v: 0.1).clamped(by: 0...0.25),
      lightLeakOpacity: 0,
      lightLeak: Resources.Leak.all.randomElement()!.resource,
      lookup: Resources.Lut.jtree.resource,
      lookupIntensity: 1,
      vignetteIntensity: CGFloat.normal(m: 0.25, v: 0.05).clamped(by: 0.15...0.3),
      stampFont: .digital,
      stampColor: 0,
      stampDateVisible: false,
      stampTimeVisible: false
    )
  }
  
  static var lifted: Self {
    .init(
      blurRadius: 0.1,
      chromaScale: 0.15,
      dustOpacity: (Int.random(in: 0...3) == 0) ? 1 : 0,
      dustParticleIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      dustHairIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      glowOpacity: 0.3,
      glowRadius: 0.25,
      glowThreshold: 0.2,
      grainOpacity: 1.0,
      grainSize: 0.3,
      lightLeakOpacity: 0,
      lightLeak: Resources.Leak.all.randomElement()!.resource,
      lookup: Resources.Lut.faded.resource,
      lookupIntensity: 1,
      vignetteIntensity: 0,
      stampFont: .digital,
      stampColor: 0,
      stampDateVisible: false,
      stampTimeVisible: false
    )
  }
  
  static var hybrid: Self {
    .init(
      blurRadius: 0.25,
      chromaScale: 0.7,
      dustOpacity: (Int.random(in: 0...2) == 0) ? 1 : 0,
      dustParticleIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      dustHairIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      glowOpacity: 0.3,
      glowRadius: 0.25,
      glowThreshold: 0.2,
      grainOpacity: CGFloat.normal(m: 0.7, v: 0.1).clamped(by: 0.5...0.8),
      grainSize: CGFloat.normal(m: 0.2, v: 0.1).clamped(by: 0...0.25),
      lightLeakOpacity: (Int.random(in: 0...2) == 0) ? 1 : 0,
      lightLeak: Resources.Leak.all.randomElement()!.resource,
      lookup: Resources.Lut.hybrid1.resource,
      lookupIntensity: 1,
      vignetteIntensity: CGFloat.normal(m: 0.7, v: 0.2).clamped(by: 0.5...0.9),
      stampFont: .digital,
      stampColor: 0,
      stampDateVisible: false,
      stampTimeVisible: false
    )
  }
  
  static var disposable: Self {
    .init(
      blurRadius: 0.25,
      chromaScale: 0.5,
      dustOpacity: (Int.random(in: 0...3) == 0) ? 1 : 0,
      dustParticleIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      dustHairIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      glowOpacity: 0.3,
      glowRadius: 0.25,
      glowThreshold: 0.2,
      grainOpacity: CGFloat.normal(m: 0.7, v: 0.1).clamped(by: 0.5...0.8),
      grainSize: CGFloat.normal(m: 0.2, v: 0.1).clamped(by: 0...0.25),
      lightLeakOpacity: 0,
      lightLeak: Resources.Leak.all.randomElement()!.resource,
      lookup: Resources.Lut.disposable4.resource,
      lookupIntensity: 1,
      vignetteIntensity: CGFloat.normal(m: 0.7, v: 0.2).clamped(by: 0.5...0.9),
      stampFont: .digital,
      stampColor: 0,
      stampDateVisible: false,
      stampTimeVisible: false
    )
  }
  
  static var old: Self {
    .init(
      blurRadius: 0.35,
      chromaScale: 0.3,
      dustOpacity: (Int.random(in: 0...2) == 0) ? 1 : 0,
      dustParticleIntensity: CGFloat.normal(m: 0.5, v: 0.3).clamped(by: 0...0.8),
      dustHairIntensity: CGFloat.normal(m: 0.5, v: 0.3).clamped(by: 0...0.8),
      glowOpacity: 0.3,
      glowRadius: 0.25,
      glowThreshold: 0.2,
      grainOpacity: 0.8,
      grainSize: 0.3,
      lightLeakOpacity: (Int.random(in: 0...2) == 0) ? 1 : 0,
      lightLeak: Resources.Leak.all.randomElement()!.resource,
      lookup: {
        return Gen
          .frequency(
            //(1, Gen.always(Resources.Lut.disposable17.resource)), // purple
            (2, Gen.always(Resources.Lut.pastel4.resource))
          ).run()
      }(),
      lookupIntensity: 1,
      vignetteIntensity: CGFloat.normal(m: 0.2, v: 0.2).clamped(by: 0...0.4),
      stampFont: .digital,
      stampColor: 0,
      stampDateVisible: false,
      stampTimeVisible: false
    )
  }
  
  static var random: Self {
    return Gen
      .frequency(
        (1, Gen.always(FilteredImage.Parameters.old)),
        (1, Gen.always(FilteredImage.Parameters.hybrid)),
        (2, Gen.always(FilteredImage.Parameters.lifted)),
        (2, Gen.always(FilteredImage.Parameters.jtree)),
        (1, Gen.always(FilteredImage.Parameters.disposable))
      ).run()
  }
}

public extension FilteredImage.Parameters {
  static var empty: Self {
    .init(
      blurRadius: 0,
      chromaScale: 0,
      dustOpacity: 0,
      dustParticleIntensity: 0,
      dustHairIntensity: 0,
      glowOpacity: 0,
      glowRadius: 0,
      glowThreshold: 0,
      grainOpacity: 0,
      grainSize: 0,
      lightLeakOpacity: 0,
      lightLeak: Resources.Leak.all[0].resource,
      lookup: Resources.Lut.pastel4.resource,
      lookupIntensity: 1,
      vignetteIntensity: 0,
      stampFont: .digital,
      stampColor: 0,
//      vignetteOffsetX: 0,
//      vignetteOffsetY: 0,
      stampDateVisible: false,
      stampTimeVisible: false
    )
  }
  
  static var legacyRandom: Self {
//    parameters.lookupIntensity = CGFloat.gaussRandom(mean: 0.8, variance: 0.1).clamp(0.7, 0.9)
//    var potentialImageNames = OverlayImageType.lookup.imageNames
//    potentialImageNames.removeAll { $0 == "lut1.png" }
//    parameters.lookupImageName = potentialImageNames[Int.random(in: 0...(potentialImageNames.count - 1))]
//
//    parameters.glowThreshold = CGFloat.gaussRandom(mean: 0.2, variance: 0.1).clamp(0.1, 0.3)
//    parameters.glowRadius = CGFloat.gaussRandom(mean: 50, variance: 20).clamp(30, 70)
//    parameters.glowOpacity = CGFloat.gaussRandom(mean: 0.5, variance: 0.1).clamp(0.2, 0.6)
//
//    let randomOpacity = Int.random(in: 0...5)
//    parameters.lightLeakOpacity = (randomOpacity == 0) ? 1.0 : 0.0
//    let overlayImageNames = OverlayImageType.lightLeak.imageNames
//    let randomIndex = Int.random(in: 0..<overlayImageNames.count)
//    parameters.lightLeakOverlayName = overlayImageNames[randomIndex]
//
//    let dustOpacity = CGFloat.gaussRandom(mean: 0.7, variance: 0.1).clamp(0.5, 0.8)
//    parameters.dustOpacity = (Int.random(in: 0...3) == 0) ? dustOpacity : 0.0
//    let dustNames = OverlayImageType.dust.imageNames
//    let dustIndex = Int.random(in: 0..<dustNames.count)
//    parameters.dustOverlayImageName = dustNames[dustIndex]
//
//    parameters.grainSize = 1.0
//    parameters.grainOpacity = CGFloat.gaussRandom(mean: 0.7, variance: 0.1).clamp(0.5, 0.8)
//
//    parameters.chromaScale = CGFloat.gaussRandom(mean: 0.008, variance: 0.002).clamp(0.005, 0.012)
//
//    let randomBlur = CGFloat.gaussRandom(mean: 3, variance: 2).clamp(3, 5)
//    parameters.blurRadius = (Int.random(in: 0...6) == 0) ? randomBlur : 1.25
//
//    parameters.vignetteOffsetX = CGFloat.gaussRandom(mean: 0.0, variance: 0.2).clamp(-0.3, 0.3)
//    parameters.vignetteOffsetY = CGFloat.gaussRandom(mean: 0.0, variance: 0.2).clamp(-0.3, 0.3)
//    parameters.vignetteIntensity = CGFloat.gaussRandom(mean: 0.45, variance: 0.2).clamp(0.3, 0.6)
//
//    parameters.stampDateVisible = false
//    parameters.stampTimeVisible = false
    .init(
      blurRadius: (Int.random(in: 0...6) == 0)
        ? CGFloat.normal(m: 0.6, v: 0.4).clamped(by: 0.6...1)
        : 0.25,
      chromaScale: CGFloat.normal(m: 0.32, v: 0.08).clamped(by: 0.2...0.48),
      dustOpacity: (Int.random(in: 0...3) == 0) ? 1 : 0,
      dustParticleIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      dustHairIntensity: CGFloat.normal(m: 0.4, v: 0.3).clamped(by: 0...0.8),
      glowOpacity: CGFloat.normal(m: 0.5, v: 0.1).clamped(by: 0.1...0.6),
      glowRadius: CGFloat.normal(m: 0.03, v: 0.01).clamped(by: 0.01...0.05),
      glowThreshold: CGFloat.normal(m: 0.2, v: 0.1).clamped(by: 0.1...0.3),
      grainOpacity: CGFloat.normal(m: 0.7, v: 0.1).clamped(by: 0.5...0.8),
      grainSize: 0,
      lightLeakOpacity: (Int.random(in: 0...5) == 0) ? 1 : 0,
      lightLeak: Resources.Leak.all.randomElement()!.resource,
      lookup: Resources.Lut.all.randomElement()!.resource,
      lookupIntensity: CGFloat.normal(m: 0.8, v: 0.1).clamped(by: 0.7...0.9),
      vignetteIntensity: CGFloat.normal(m: 0.45, v: 0.2).clamped(by: 0.3...0.6),
      stampFont: .digital,
      stampColor: 0,
      stampDateVisible: false,
      stampTimeVisible: false
    )
  }
}

extension FilteredImage: Identifiable {}
