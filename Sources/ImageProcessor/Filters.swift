import CoreImage
import Foundation
import UIKit
import DazeFoundation

public typealias Filter<T> = (T) -> T

// if the resulting image size is fractional, core image will
// round up to the nearest whole number and fill the empty space with black.
// we use rounding so resulting image dimensions are whole numbers
func roundingPolicy(_ value: CGFloat) -> CGFloat {
  value.rounded(.down)
}

// MARK: - Crop
struct Crop {
  let transformation: Transformation.Rect
}

extension Crop {
  func filter(_ image: CIImage) -> CIImage {
    let bounds = transformation.transform(image.extent)
    let wholeNumberBounds = CGRect(
      x: roundingPolicy(bounds.origin.x),
      y: roundingPolicy(bounds.origin.y),
      width: roundingPolicy(bounds.size.width),
      height: roundingPolicy(bounds.size.height)
    )
    return image.cropped(to: wholeNumberBounds)
  }
}

// MARK: - Size
struct Size {
  let transformation: Transformation.Rect.Size
}

extension Size {
  func filter(_ image: CIImage) -> CIImage {
    let scaledSize = transformation.transform(image.extent)
    let scaleX = roundingPolicy(scaledSize.width) / image.extent.width
    let scaleY = roundingPolicy(scaledSize.height) / image.extent.height
    if scaleX == scaleY && scaleX < 1 {
      return CIFilter(
        name: "CILanczosScaleTransform",
        parameters: [
          kCIInputImageKey: image,
          kCIInputScaleKey: scaleX
        ]
      )!.outputImage!
    } else {
      let scaleTransform = CGAffineTransform(
        scaleX: scaleX,
        y: scaleY
      )
      return image.transformed(by: scaleTransform)
    }
  }
}

// MARK: - Position
struct Position {
  let transformation: Transformation.Rect.Position
}

extension Position {
  func filter(_ image: CIImage) -> CIImage {
    let oldPoint = image.extent
    let newPoint = transformation.transform(oldPoint)
    let translationX = newPoint.x - oldPoint.origin.x
    let translationY = newPoint.y - oldPoint.origin.y
    return image.transformed(by: CGAffineTransform(
      translationX: roundingPolicy(translationX),
      y: roundingPolicy(translationY)
    ))
  }
}

// MARK: - Rotate
/// filter that rotates around the center of the image
struct Rotate {
  let unit: RotationUnit
}

extension Rotate {
  func filter(_ image: CIImage) -> CIImage {
    let radians = unit.radians(image.extent)
    guard radians != 0 else { return image }
    let center = CGPoint(x: image.extent.midX, y: image.extent.midY)
    return image.transformed(
      by: CGAffineTransform(translationX: center.x, y: center.y)
        .rotated(by: radians)
        .translatedBy(x: -center.x, y: -center.y)
    )
  }
}

// MARK: - Blur
/// A filter that applies a Gaussian blur
struct Blur {
  let radius: ImageUnit
}

extension Blur {
  func filter(_ image: CIImage) -> CIImage {
    image
      .clampedToExtent()
      .applyingGaussianBlur(sigma: radius.pixels(image.extent))
      .cropped(to: image.extent)
  }
}

// MARK: - Extended
struct Extended {}
extension Extended {
  func filter(_ image: CIImage) -> CIImage {
    image.clampedToExtent()
  }
}

struct Vignette {
  /// a radius of 1.0 fills the entire image
  let angleAtEdge: CGFloat
  let intensity: CGFloat

  init(angleAtEdge: CGFloat, intensity: CGFloat) {
    self.angleAtEdge = angleAtEdge
    self.intensity = intensity
  }
}

extension Vignette {
  func filter1(_ image: CIImage) -> CIImage {
    MetalVignette(
      center: CIVector(cgPoint: image.extent.center),
      angleAtEdge: angleAtEdge,
      intensity: intensity,
      compensation: 0
    ).filter(image)
  }
  
  func filter(_ image: CIImage) -> CIImage {
    return ImageProcessor.intensity(self.intensity) {
      MetalVignette(
        center: CIVector(cgPoint: image.extent.center),
        angleAtEdge: angleAtEdge,
        intensity: 1.0,
        compensation: 0
      ).filter
    }(image)
//    return MetalVignette(
//      center: CIVector(cgPoint: image.extent.center),
//      angleAtEdge: angleAtEdge,
//      intensity: intensity,
//      compensation: 0
//    ).filter(image)
  }
}

// MARK: - Vignette
struct GaussianVignette {
  /// a radius of 1.0 fills the entire image
  let radius: CGFloat
  let intensity: CGFloat

  init(radius: CGFloat, intensity: CGFloat) {
    self.radius = radius
    self.intensity = intensity
  }
}

extension GaussianVignette {
  func basicFilter(_ image: CIImage) -> CIImage {
    image.applyingFilter(
      "CIVignette",
      parameters: [
        kCIInputRadiusKey: radius,
        kCIInputIntensityKey: intensity,
      ]
    )
  }

  func filter(_ image: CIImage) -> CIImage {
    let smallerSide = min(image.extent.size.width, image.extent.size.height)
    let mask = GaussianGradient(
      radius: radius * smallerSide,
      size: CGSize(width: smallerSide, height: smallerSide),
      outerColor: .black,
      innerColor: .white
    ).generate()

    return image.filter {
      Brightness(intensity: -intensity / 4).filter
      Saturation(intensity: 1 + intensity / 4).filter
      Mask(
        blendImage: image,
        mask: mask.filter {
          //Brightness(intensity: intensity / 4).filter
          //Saturation(intensity: 1 - intensity / 4).filter
          size(.filling(image.extent.size))
          position(.constant(image.extent.origin))
        }
      ).filter
    }
  }
}

// MARK: - GaussianGradient
struct GaussianGradient {
  let radius: CGFloat
  let size: CGSize
  let outerColor: CIColor
  let innerColor: CIColor
}

extension GaussianGradient {
  func generate() -> CIImage {
    let rect = CGRect(origin: .zero, size: size)
    return CIFilter(
      name: "CIGaussianGradient",
      parameters: [
        kCIInputRadiusKey: radius,
        kCIInputCenterKey: CIVector(cgPoint: rect.center),
        "inputColor0": innerColor,
        "inputColor1": outerColor,
      ]
    )!
      .outputImage!
      .filter {
        Crop(transformation: .constant(rect)).filter
      }
  }
}

// MARK: - Blend
public struct Blend {
  let blendImage: CIImage
  let mode: Mode

  public enum Mode {
    case overlay
    case sourceOver
    case addition
    case softLight
    case screen
    case linearDodge

    var coreImage: String {
      switch self {
      case .overlay: return "CIOverlayBlendMode"
      case .sourceOver: return "CISourceOverCompositing"
      case .addition: return "CIAdditionCompositing"
      case .softLight: return "CISoftLightBlendMode"
      case .screen: return "CIScreenBlendMode"
      case .linearDodge: return "CILinearDodgeBlendMode"
      }
    }
  }
}

extension Blend {
  func filter(_ image: CIImage) -> CIImage {
    blendImage.applyingFilter(
      mode.coreImage,
      parameters: [
        kCIInputBackgroundImageKey: image,
      ]
    )
  }
}

// MARK: - Mask
struct Mask {
  let blendImage: CIImage
  let mask: CIImage
}

extension Mask {
  func filter(_ image: CIImage) -> CIImage {
    blendImage.applyingFilter(
      "CIBlendWithMask",
      parameters: [
        kCIInputBackgroundImageKey: image,
        kCIInputMaskImageKey: mask,
      ]
    )
  }
}

// MARK: - Intensity
/// A filter that applies another filter with an intensity
struct Intensity<T> {
  let intensified: Filter<T>
  let intensity: CGFloat

  init(intensified: @escaping Filter<T>, intensity: CGFloat) {
    self.intensified = intensified
    self.intensity = intensity.clamped(by: .normal)
  }
}

extension Intensity where T == CIImage {
  func filter(_ image: CIImage) -> CIImage {
    let filteredImage = intensified(image)

    var alphaAdjustedImage = filteredImage
    if intensity < 1 {
      alphaAdjustedImage = alphaAdjustedImage.applyingFilter(
        "CIColorMatrix",
        parameters: [
          "inputAVector": CIVector(x: 0, y: 0, z: 0, w: intensity),
        ]
      )
    }
    return Blend(blendImage: alphaAdjustedImage, mode: .sourceOver).filter(image)
  }
}

// MARK: - Contrast
struct Contrast {
  let intensity: CGFloat
}

extension Contrast {
  func filter(_ image: CIImage) -> CIImage {
    image.applyingFilter(
      "CIColorControls",
      parameters: ["inputContrast": intensity]
    )
  }
}

// MARK: - Saturation
struct Saturation {
  let intensity: CGFloat
}

extension Saturation {
  func filter(_ image: CIImage) -> CIImage {
    image.applyingFilter(
      "CIColorControls",
      parameters: ["inputSaturation": intensity]
    )
  }
}

// MARK: - Brightness
struct Brightness {
  let intensity: CGFloat
}

extension Brightness {
  func filter(_ image: CIImage) -> CIImage {
    image.applyingFilter(
      "CIColorControls",
      parameters: ["inputBrightness": intensity]
    )
  }
}

// MARK: - Random
/// Generates an image of uniformly random colored pixels
struct Random {
  let size: CGSize
}

extension Random {
  func generator() -> CIImage {
    CIFilter(name: "CIRandomGenerator")!
      .outputImage!
      .cropped(to: .init(origin: .zero, size: size))
  }
}

// MARK: - Grain
struct Grain {
  /// The size of the grain as a factor of the image size. A value of 1 will apply grain with the same amount of pixels as the filtered image
  let size: CGFloat
  /// A normalized value controlling how visible the grain is
  let intensity: CGFloat
  /// A normalized value controlling how colorful the grain is
  let color: CGFloat
}

extension Grain {
  func filter(_ image: CIImage) -> CIImage {
    let noise = Random(
      size: .init(
        width: image.extent.width * size,
        height: image.extent.height * size
      )
    )
    .generator()
    .filter {
      Contrast(intensity: intensity).filter
      Saturation(intensity: color).filter
      Size(transformation: .constant(image.extent.size)).filter
      Position(transformation: .center(in: image.extent)).filter
    }

    return image.filter {
      Blend(
        blendImage: noise,
        mode: .overlay
      ).filter
    }
  }
}

struct GrainOverlay<T> {
  let size: CGFloat
  let intensity: CGFloat
  let overlay: T
}

extension GrainOverlay where T == CIImage {
  func filter(_ image: CIImage) -> CIImage {
    let noise = overlay.filter {
      rotate(.byMatchingOrientation(image.extent))
      ImageProcessor.size(.filling(image.extent.size))
      ImageProcessor.size(.scalingBy(1 + size))
      position(.center(in: image.extent))
      crop(.constant(image.extent))
    }
    return image.filter {
      ImageProcessor.intensity(intensity) {
        blend(noise, mode: .overlay)
      }
    }
  }
}

struct ChromaticAberration {
  let intensity: CGFloat
}

extension ChromaticAberration {
  func filter1(_ image: CIImage) -> CIImage {
    let red = image.filter {
      component(.red)
      size(.scalingBy(1 + intensity))
      position(.center(in: image.extent))
    }
    let green = image.filter {
      component(.green)
      size(.scalingBy(1 + intensity / 2))
      position(.center(in: image.extent))
    }
    let blue = image.filter {
      component(.blue)
    }
    return red.filter {
      blend(
        blend(blue, mode: .addition)(green),
        mode: .addition
      )
      crop(.constant(image.extent))
    }
  }
  
  func filter(_ image: CIImage) -> CIImage {
    return MetalChromab(
      center: CIVector(cgPoint: image.extent.center),
      size: CIVector(x: image.extent.size.width, y: image.extent.size.height),
      exponent: 1,
      intensity: intensity,
      base: intensity / 15
    ).filter(image)
  }
}

public struct Component {
  public struct Matrix {
    let r: CIVector
    let g: CIVector
    let b: CIVector
    let a: CIVector
    
    init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
      self.r = CIVector(x: r, y: 0, z: 0, w: 0)
      self.g = CIVector(x: 0, y: g, z: 0, w: 0)
      self.b = CIVector(x: 0, y: 0, z: b, w: 0)
      self.a = CIVector(x: 0, y: 0, z: 0, w: a)
    }
    
    public static let red: Self = .init(r: 1, g: 0, b: 0, a: 1)
    public static let green: Self = .init(r: 0, g: 1, b: 0, a: 1)
    public static let blue: Self = .init(r: 0, g: 0, b: 1, a: 1)
    public static func alpha(_ value: CGFloat) -> Self { .init(r: 1, g: 1, b: 1, a: value) }
  }

  let matrix: Matrix
}

extension Component {
  func filter(_ image: CIImage) -> CIImage {
    return image.applyingFilter(
      "CIColorMatrix",
      parameters: [
        "inputRVector": matrix.r,
        "inputGVector": matrix.g,
        "inputBVector": matrix.b,
        "inputAVector": matrix.a
      ]
    )
  }
}

struct Glow {
  let radius: ImageUnit
  let intensity: CGFloat
  let threshold: CGFloat
}

extension Glow {
  func filter(_ image: CIImage) -> CIImage {
    return image.filter {
      ImageProcessor.intensity(self.intensity) {
        BrightnessThreshold(threshold: threshold).filter
        blur(radius: radius)
        blend(image, mode: .softLight)
      }
    }
  }
}

struct Lut {
  let lut: CIImage
  let intensity: CGFloat
}

extension Lut {
  func filter(_ image: CIImage) -> CIImage {
    return LutFilter(lut: lut, intensity: intensity).filter(image)
  }
}

struct Leak {
  let overlay: CIImage
  let intensity: CGFloat
}

extension Leak {
  func filter(_ image: CIImage) -> CIImage {
    let filledOverlay = overlay.filter {
      blur(radius: .pixels(10))
      size(.filling(image.extent.size))
      position(.center(in: image.extent))
    }
    return Intensity(
      intensified: blend(filledOverlay, mode: .screen),
      intensity: intensity
    ).filter(image)
  }
}

struct DateStamp {
  let string: NSAttributedString
}

extension DateStamp {
  func filter(_ image: CIImage) -> CIImage {
    guard string.length > 0 else { return image }
    let margin = ImageUnit.normalized(0.09)
    let marginPixels = margin.pixels(image.extent)
    //let textSize = ImageUnit.normalized(0.03)   // textheight * x
    let textImage = CIImage.text(string: string).filter { textImage in
      //size(.scalingBy())
      //blur(radius: .pixels(textImage.extent.height / 5000))
      //Burn(radius: .pixels(textImage.extent.height * 0.1), intensity: 1).filter
      // probably slightly different at different sizes due to how we cut off at 0.03 in kernel
      Burn(
        radius: .pixels(ImageUnit.normalized(0.003).pixels(image.extent)),
        intensity: 0.75
      ).filter
    }
    return image.filter {
      let rotateAmount: CGFloat = image.extent.isPortrait ? 90 : 0
      rotate(.degrees(rotateAmount))
      position(.constant(.zero))
        buildFilter { (rotatedImage: CIImage) in
        blend(
          textImage.filter {
            position(.constant(.init(
              x: rotatedImage.extent.width - textImage.extent.width - marginPixels,
              y: marginPixels
            )))
          },
          mode: .linearDodge
        )
      }
      rotate(.degrees(-rotateAmount))
      position(.constant(.zero))
    }
  }
}

struct Burn {
  let radius: ImageUnit
  let intensity: CGFloat
}

extension Burn {
  func filter(_ image: CIImage) -> CIImage {
    let radiusPixels = radius.pixels(image.extent)
    print("height \(image.extent.height) radius \(radiusPixels)")
    let newExtent = image.extent.insetBy(dx: -radiusPixels, dy: -radiusPixels)
    let background = CIImage.blank(color: .black, size: newExtent.size)
    return background.filter {
      blend(
        image.filter { position(.offset(x: radiusPixels, y: radiusPixels)) },
        mode: .sourceOver
      )
      MetalBurn(radius: radiusPixels, intensity: intensity).filter
    }
  }
}

struct Dust<T> {
  let overlay: T
  let opacity: CGFloat
}

extension Dust where T == CIImage {
  func filter(_ image: CIImage) -> CIImage {
    return image.filter {
      intensity(opacity) {
        blend(
          overlay.filter {
            blur(radius: .normalized(0.0005))
            rotate(.byMatchingOrientation(image.extent))
            size(.fillingAspect(image.extent.size))
            position(.center(in: image.extent))
          },
          mode: .screen
        )
      }
      crop(.constant(image.extent))
    }
  }
}
