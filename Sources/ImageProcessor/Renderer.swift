import CoreImage
import DazeFoundation

public class Renderer {
  public let colorSpace: CGColorSpace
  public let context: CIContext
  
  init(
    colorSpace: CGColorSpace,
    context: CIContext
  ) {
    self.colorSpace = colorSpace
    self.context = context
  }
  
  static func with(format: CIFormat) -> Renderer {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CIContext(
      mtlDevice: MTLCreateSystemDefaultDevice()!,
      options: [
        CIContextOption.workingColorSpace: colorSpace,
        CIContextOption.workingFormat: format,
      ]
    )
    return .init(
      colorSpace: colorSpace,
      context: context
    )
  }
  
  // thread safe?
  public static let highQuality: Renderer = .with(format: .RGBAh)
  public static let lowQuality: Renderer = .with(format: .RGBA8)
  public static let thumbnailQuality: Renderer = .with(format: .RGBA8)
}

public extension CIImage {
  func render(compression: CGFloat, renderer: Renderer) throws -> Data {
    guard let data = renderer.context.jpegRepresentation(
      of: self,
      colorSpace: renderer.colorSpace,
      options: [
        kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: compression,
      ]
    )
    else { throw GenericError("CIImage render to Data failed") }
    renderer.context.clearCaches()
    return data
  }
  
  func render(renderer: Renderer) throws -> CGImage {
    guard let cgimage = renderer.context.createCGImage(self, from: extent) else {
      throw GenericError("CIImage render to CGImage failed")
    }
    renderer.context.clearCaches()
    return cgimage
  }
  
  func render(url: URL, compression: CGFloat, renderer: Renderer) throws {
    try renderer.context.writeJPEGRepresentation(
      of: self,
      to: url,
      colorSpace: renderer.colorSpace,
      options: [
        kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: compression,
      ]
    )
    renderer.context.clearCaches()
  }
}
