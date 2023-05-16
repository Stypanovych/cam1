import Foundation
import CoreStore
import CoreGraphics
import Resources

extension FilteredImage.Parameters: CoreStoreBacked {
  typealias CoreStoreType = CoreStoreFilterParameters
  
  static func map(_ object: CoreStoreFilterParameters) -> FilteredImage.Parameters {
    return .init(
      blurRadius: CGFloat(object.blurRadius),
      chromaScale: CGFloat(object.chromaScale),
      dustOpacity: CGFloat(object.dustOpacity),
      dustParticleIntensity: CGFloat(object.dustParticleIntensity),
      dustHairIntensity: CGFloat(object.dustHairIntensity),
      glowOpacity: CGFloat(object.glowOpacity),
      glowRadius: CGFloat(object.glowRadius),
      glowThreshold: CGFloat(object.glowThreshold),
      grainOpacity: CGFloat(object.grainOpacity),
      grainSize: CGFloat(object.grainSize),
      lightLeakOpacity: CGFloat(object.lightLeakOpacity),
      lightLeak: Resources.Leak.named(object.lightLeakOverlayName).resource,
      lookup: Resources.Lut.named(object.lookupImageName).resource,
      lookupIntensity: CGFloat(object.lookupIntensity),
      vignetteIntensity: CGFloat(object.vignetteIntensity),
      stampFont: StampFont(rawValue: object.stampFont) ?? .digital,
      stampColor: CGFloat(object.stampColor),
      stampDateVisible: object.stampDateVisible,
      stampTimeVisible: object.stampTimeVisible
    )
  }
  
  func sync(_ object: CoreStoreFilterParameters) {
    object.blurRadius = Float(blurRadius)
    object.chromaScale = Float(chromaScale)
    object.dustOpacity = Float(dustOpacity)
    object.dustParticleIntensity = Float(dustParticleIntensity)
    object.dustHairIntensity = Float(dustHairIntensity)
    object.glowOpacity = Float(glowOpacity)
    object.glowRadius = Float(glowRadius)
    object.glowThreshold = Float(glowThreshold)
    object.grainOpacity = Float(grainOpacity)
    object.grainSize = Float(grainSize)
    object.lightLeakOpacity = Float(lightLeakOpacity)
    object.lightLeakOverlayName = lightLeak.name
    object.lookupImageName = lookup.name
    object.lookupIntensity = Float(lookupIntensity)
    object.vignetteIntensity = Float(vignetteIntensity)
    object.stampFont = stampFont.rawValue
    object.stampColor = Float(stampColor)
    object.stampDateVisible = stampDateVisible
    object.stampTimeVisible = stampTimeVisible
  }
}

extension CoreStorePreset: Identifiable {}

extension User.Preset: CoreStoreBacked {
  typealias CoreStoreType = CoreStorePreset
  
  static func map(_ object: CoreStorePreset) -> User.Preset {
    return .init(
      id: object.id,
      name: object.name,
      creationDate: object.creationDate,
      parameters: FilteredImage.Parameters.map(object.parameters!)
    )
  }
  
  func sync(_ object: CoreStorePreset) {
    object.id = id
    object.name = name
    object.creationDate = creationDate
    parameters.sync(object.parameters!)
  }
}
