import Foundation
import CoreImage

private var data: Data = {
  let url = Bundle(identifier: "com.darrenasaro.MetalLib")!.url(forResource: "default", withExtension: "metallib")!
  return try! Data(contentsOf: url)
}()

//class MetalFilter: CIFilter, KernelContainer {
//  static let functionName: String = "bitch"
//
//  static var kernel: CIKernel = {
//    return try! CIKernel(functionName: functionName, fromMetalLibraryData: data)
//  }()
//
//  @objc dynamic var inputImage: CIImage?
//
//  //let functionName: String
//  var arguments: [Any]
//
//  init(arguments: [Any]) {
//    self.arguments = arguments
//    super.init()
//  }
//
//  func applyKernel(image: CIImage, kernel: CIKernel, arguments: [Any]) -> CIImage? {
//    return kernel.apply(
//      extent: image.extent,
//      roiCallback: { (index: Int32, rect: CGRect) in rect },
//      arguments: arguments
//    )!
//  }
//
//  override var outputImage: CIImage? {
//    guard let inputImage = inputImage else { return nil }
//    arguments.insert(inputImage, at: 0)
//    return applyKernel(image: inputImage, kernel: kernel, arguments: arguments)
//  }
//
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//}

//class MetalWarpFilter: MetalFilter {
//  static var kernel: CIKernel = {
//    return try! CIWarpKernel(functionName: functionName, fromMetalLibraryData: data)
//  }()
//
//  override var outputImage: CIImage? {
//    guard let inputImage = inputImage else { return nil }
//    return kernel.apply(
//      extent: inputImage.extent,
//      roiCallback: { (index: Int32, rect: CGRect) in rect },
//      image: inputImage,
//      arguments: arguments
//    )
//  }
//}

protocol MetalFilter: AnyObject {
  static var functionName: String { get }
  associatedtype Kernel: CIKernel
  static var kernel: Kernel { get }
  var inputImage: CIImage? { get set }
  var arguments: [Any] { get set }
}

extension MetalFilter {
  var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    arguments.insert(inputImage, at: 0)
    return Self.kernel.apply(
      extent: inputImage.extent,
      roiCallback: { (index: Int32, rect: CGRect) in rect },
      arguments: arguments
    )!
  }
  
  func filter(_ image: CIImage) -> CIImage {
    inputImage = image
    return outputImage!
  }
}

protocol MetalWarpFilter: MetalFilter where Kernel == CIWarpKernel {}
protocol MetalColorFilter: MetalFilter where Kernel == CIColorKernel {}

class BrightnessThreshold: MetalColorFilter {
  static var functionName: String = "brightnessThreshold"
  static var kernel: CIColorKernel = try! CIColorKernel(functionName: functionName, fromMetalLibraryData: data)
  var arguments: [Any]
  var inputImage: CIImage?
  
  init(threshold: CGFloat) {
    arguments = [threshold]
  }
}

class LutFilter: MetalFilter {
  static var functionName: String = "lut"
  static var kernel: CIKernel = try! CIKernel(functionName: functionName, fromMetalLibraryData: data)
  var arguments: [Any]
  var inputImage: CIImage?
  
  init(lut: CIImage, intensity: CGFloat) {
    arguments = [lut, intensity]
  }
}

class MetalBurn: MetalFilter {
  static var functionName: String = "burn"
  static var kernel: CIKernel = try! CIKernel(functionName: functionName, fromMetalLibraryData: data)
  var arguments: [Any]
  var inputImage: CIImage?
  private let radius: CGFloat
  
  init(radius: CGFloat, intensity: CGFloat) {
    self.radius = radius
    arguments = [radius, intensity]
  }
  
  var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    arguments.insert(inputImage, at: 0)
    return Self.kernel.apply(
      extent: inputImage.extent,
      roiCallback: { (index: Int32, rect: CGRect) in rect.insetBy(dx: -self.radius, dy: -self.radius) },
      arguments: arguments
    )!
  }
}

class MetalVignette: MetalFilter {
  static var functionName: String = "vignette"
  static var kernel: CIKernel = try! CIKernel(functionName: functionName, fromMetalLibraryData: data)
  var arguments: [Any]
  var inputImage: CIImage?
  
  init(center: CIVector, angleAtEdge: CGFloat, intensity: CGFloat, compensation: CGFloat) {
    arguments = [center, angleAtEdge, intensity, compensation]
  }
}

class MetalChromab: MetalFilter {
  static var functionName: String = "chromab"
  static var kernel: CIKernel = try! CIKernel(functionName: functionName, fromMetalLibraryData: data)
  var arguments: [Any]
  var inputImage: CIImage?
  
  init(center: CIVector, size: CIVector, exponent: CGFloat, intensity: CGFloat, base: CGFloat) {
    arguments = [center, size, exponent, intensity, base]
  }
}

//class MetalRed: MetalFilter {
//  static var functionName: String = "red"
//  static var kernel: CIKernel = try! CIKernel(functionName: functionName, fromMetalLibraryData: data)
//  var arguments: [Any]
//  var inputImage: CIImage?
//
//  init() {
//    arguments = []
//  }
//
//  var outputImage: CIImage? {
//    guard let inputImage = inputImage else { return nil }
//    arguments.insert(inputImage, at: 0)
//    return Self.kernel.apply(
//      extent: inputImage.extent,
//      roiCallback: { (index: Int32, rect: CGRect) in
//        CGRect(x: 0, y: 0, width: 400, height: 100)
//      },
//      arguments: arguments
//    )!
//  }
//}
