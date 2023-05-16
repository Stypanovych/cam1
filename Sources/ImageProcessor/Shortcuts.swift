import CoreImage

public func passthrough() -> Filter<CIImage> {
  { $0 }
}

public func buildFilter(from ciFilter: CIFilter) -> Filter<CIImage> {
  { image in
    ciFilter.setValue(image, forKey: kCIInputImageKey)
    return ciFilter.outputImage!
  }
}

public func size(_ transformation: Transformation.Rect.Size) -> Filter<CIImage> {
  Size(transformation: transformation).filter
}

public func position(_ transformation: Transformation.Rect.Position) -> Filter<CIImage> {
  Position(transformation: transformation).filter
}

public func rotate(_ unit: RotationUnit) -> Filter<CIImage> {
  Rotate(unit: unit).filter
}

public func crop(_ transformation: Transformation.Rect) -> Filter<CIImage> {
  Crop(transformation: transformation).filter
}

public func blur(radius: ImageUnit) -> Filter<CIImage> {
  Blur(radius: radius).filter
}

public func vignette(angleAtEdge: CGFloat, intensity: CGFloat) -> Filter<CIImage> {
  Vignette(angleAtEdge: angleAtEdge, intensity: intensity).filter
}

public func blend(_ blendImage: CIImage, mode: Blend.Mode = .sourceOver) -> Filter<CIImage> {
  Blend(blendImage: blendImage, mode: mode).filter
}

public func intensity(_ value: CGFloat, @FilterBuilder _ filterBuilder: () -> Filter<CIImage>) -> Filter<CIImage> {
  Intensity(intensified: filterBuilder(), intensity: value).filter
}

//public func grain(size: CGFloat, intensity: CGFloat, color: CGFloat) -> Filter<CIImage> {
//  Grain(size: size, intensity: intensity, color: color).filter
//}

public func grain(overlay: CIImage, size: CGFloat, intensity: CGFloat) -> Filter<CIImage> {
  GrainOverlay(size: size, intensity: intensity, overlay: overlay).filter
}

public func extended() -> Filter<CIImage> {
  Extended().filter
}

public func mask(_ image: CIImage, with mask: CIImage) -> Filter<CIImage> {
  Mask(blendImage: image, mask: mask).filter
}

public func component(_ matrix: Component.Matrix) -> Filter<CIImage> {
  Component(matrix: matrix).filter
}

public func chromab(intensity: CGFloat) -> Filter<CIImage> {
  ChromaticAberration(intensity: intensity).filter
}

public func glow(radius: ImageUnit, intensity: CGFloat, threshold: CGFloat) -> Filter<CIImage> {
  Glow(radius: radius, intensity: intensity, threshold: threshold).filter
}

public func lut(_ image: CIImage, intensity: CGFloat) -> Filter<CIImage> {
  Lut(lut: image, intensity: intensity).filter
}

public func leak(_ overlay: CIImage, intensity: CGFloat) -> Filter<CIImage> {
  Leak(overlay: overlay, intensity: intensity).filter
}

public func dateStamp(_ string: NSAttributedString) -> Filter<CIImage> {
  DateStamp(string: string).filter
}

public func dust(_ overlay: CIImage, opacity: CGFloat) -> Filter<CIImage> {
  Dust(overlay: overlay, opacity: opacity).filter
}


