import AVKit
import Combine
import DazeFoundation
import ComposableArchitecture
//import DispoFoundation
//import Lib

// MARK: - CaptureData
public struct CaptureData<T> {
  public let metadata: Camera.CaptureData.Metadata
  public let callback: (T) -> Void
}

public typealias PhotoCallback = (Result<Camera.CaptureData, Error>) -> Void

// MARK: - PhotoCapturer
public class PhotoCapturer: NSObject, AVCapturePhotoCaptureDelegate {
  public let node: CaptureSessionNode
  public let scheduler: AnySchedulerOf<DispatchQueue>

  private var captureDevice: CaptureDevice? { node.captureDevice }
  private var photoOutput: AVCapturePhotoOutput { node.output }

  private var photoCallbackQueue: [CaptureData<Result<Camera.CaptureData, Error>>] = []

  public init(
    node: CaptureSessionNode,
    scheduler: AnySchedulerOf<DispatchQueue>
  ) {
    self.node = node
    self.scheduler = scheduler
    super.init()
  }

  public func capturePhoto(callback: @escaping PhotoCallback) {
    guard let captureDevice = self.captureDevice else { return }
    let captureData = CaptureData(
      metadata: Camera.CaptureData.Metadata(
        date: Date(),
        orientation: UIDevice.current.orientation,
        flash: captureDevice.flash
      ),
      callback: callback
    )
    photoCallbackQueue.append(captureData)
    photoOutput.capturePhoto(
      with: settings(for: captureDevice.flash),
      delegate: self
    )
  }
}

extension PhotoCapturer {
  private func settings(for flash: Camera.Settings.Flash) -> AVCapturePhotoSettings {
    let settings = AVCapturePhotoSettings()
    let flashMode: AVCaptureDevice.FlashMode = flash.avFlashMode
    settings.flashMode = photoOutput.supportedFlashModes.contains(flashMode) ? flashMode : .off
    return settings
  }

  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    let captureData = photoCallbackQueue.removeFirst()

    guard error == nil else {
      return captureData.callback(.failure(error!))
    }

    scheduler.schedule { [unowned self] in
      guard let photoData = self.process(photo, captureData.metadata) else { return }
      captureData.callback(.success(photoData))
    }
  }
}

extension PhotoCapturer {
  private func process(_ photo: AVCapturePhoto, _ metadata: Camera.CaptureData.Metadata) -> Camera.CaptureData? {
    guard
      let captureDevice = self.captureDevice,
      let data = photo.fileDataRepresentation(),
      let image = UIImage(data: data)
    else { return nil }

    let orientation = calculate(
      given: captureDevice.orientation,
      metadata.orientation
    )
    let newImage = UIImage(
      cgImage: image.cgImage!,
      scale: image.scale,
      orientation: orientation
    ).oriented

    return Camera.CaptureData(
      photo: newImage,
      metadata: metadata
      //exifData: exifData(for: photo)
    )
  }

//  private func exifData(for photo: AVCapturePhoto) -> ExifData {
//    let exifDictionary = photo.metadata[kCGImagePropertyExifDictionary as String] as? [CFString: Any]
//    let exposureTime = exifDictionary?[kCGImagePropertyExifExposureTime] as? Double
//    let lensModel = exifDictionary?[kCGImagePropertyExifLensModel] as? String
//    return [
//      "exposureTime": exposureTime.map { String($0) },
//      "lensModel": lensModel,
//    ].compactMapValues { $0 }
//  }
  //  switch orientation {
  //  case .landscapeLeft:
  //      return cameraPosition == .rear ? .up : .downMirrored
  //  case .landscapeRight:
  //      return cameraPosition == .rear ? .down : .upMirrored
  //  case .portraitUpsideDown:
  //      return cameraPosition == .rear ? .right : .leftMirrored
  //  default:
  //      return cameraPosition == .rear ? .right : .leftMirrored
  //  }
  private func calculate(
    given cameraSelection: Camera.Settings.Orientation,
    _ deviceOrientation: UIDeviceOrientation
  ) -> UIImage.Orientation {
    switch deviceOrientation {
    case .landscapeLeft: return cameraSelection == .back ? .up : .downMirrored
    case .landscapeRight: return cameraSelection == .back ? .down : .upMirrored
    case .portraitUpsideDown: return cameraSelection == .back ? .right : .leftMirrored
    default: return cameraSelection == .back ? .right : .leftMirrored
    }
  }
}

extension Camera.Settings.Flash {
  var avFlashMode: AVCaptureDevice.FlashMode {
    switch self {
    case .on: return .on
    case .off: return .off
    }
  }
}

//import Foundation
//import AVKit
//import ComposableArchitecture
//
//public struct Filtered<T> {
//  public let unfiltered: T
//  public let filtered: T
//}
//
//public struct PhotoData {
//  public let depth: UIImage?
//  public let photo: UIImage
//  public let metadata: CaptureMetadata
//}
//
//public struct CaptureMetadata {
//  public let date: Date
//  public let orientation: UIDeviceOrientation
//  public let flash: Bool
//}
//
//public struct CaptureData<T> {
//  public let metadata: CaptureMetadata
//  public let callback: (T) -> Void
//}
//
//public typealias PhotoCallback = (Result<PhotoData, Error>) -> Void
//
//public protocol PhotoCapturer {
//  var captureSession: CaptureSession { get }
//  func capturePhoto(callback: @escaping PhotoCallback)
//  func captureDepthPhoto(callback: @escaping PhotoCallback)
//}
//
//public protocol PhotoCapturerFactory {
//  func create(captureSession: CaptureSession) -> PhotoCapturer
//}
//
//public class DefaultPhotoCapturer: NSObject, PhotoCapturer, AVCapturePhotoCaptureDelegate  {
//  public let captureSession: CaptureSession
//  private let scheduler: AnySchedulerOf<DispatchQueue>
//
//  private var captureDevice: CaptureDevice? { captureSession.node.inputs.captureInput }
//  private var photoOutput: AVCapturePhotoOutput { captureSession.node.outputs.photoOutput! }
//
//  private var photoCallbackQueue: [CaptureData<Result<PhotoData, Error>>] = []
//  private var selectionEnabled: Bool = true
//
//  public init(
//    captureSession: CaptureSession,
//    scheduler: AnySchedulerOf<DispatchQueue>
//  ) {
//    self.captureSession = captureSession
//    self.scheduler = scheduler
//    super.init()
//  }
//
//  public func capturePhoto(callback: @escaping PhotoCallback) {
//    //configureForNoDepth(output: photoOutput)
//    capturePhoto(callback: callback, queue: &photoCallbackQueue)
//  }
//
//  public func captureDepthPhoto(callback: @escaping PhotoCallback) {
//    //configureForDepth(output: photoOutput)
//    capturePhoto(callback: callback, queue: &photoCallbackQueue)
//  }
//
//  private func capturePhoto<T>(callback: @escaping (T) -> Void, queue: inout [CaptureData<T>]) {
//    guard let captureDevice = captureDevice else { return }
//    let captureData = CaptureData(
//      metadata: CaptureMetadata(
//        date: Date(),
//        orientation: UIDevice.current.orientation,
//        flash: captureDevice.flash.bool
//      ),
//      callback: callback
//    )
//    queue.append(captureData)
//    photoOutput.capturePhoto(with: settings(for: captureDevice.flash), delegate: self)
//  }
//}
////
//extension DefaultPhotoCapturer {
//  private func settings(for flash: CaptureDeviceSettings.Flash) -> AVCapturePhotoSettings {
//    let settings = AVCapturePhotoSettings()
//    let flashMode: AVCaptureDevice.FlashMode = flash.mode
//    settings.flashMode = photoOutput.supportedFlashModes.contains(flashMode) ? flashMode : .off
//    settings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliveryEnabled
//    return settings
//  }
//
//  private func configureForNoDepth(output: AVCapturePhotoOutput) {
//    output.isDepthDataDeliveryEnabled = false
//  }
//
//  private func configureForDepth(output: AVCapturePhotoOutput) {
//    output.isDepthDataDeliveryEnabled = output.isDepthDataDeliverySupported
//  }
//
//  public func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
//    selectionEnabled = false
//  }
//
//  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//    let captureData = photoCallbackQueue.removeFirst()
//
//    selectionEnabled = true
//    guard error == nil else {
//      return captureData.callback(.failure(error!))
//    }
//
//    scheduler.schedule { [weak self] in
//      guard let photoData = self?.process(photo, captureData.metadata) else { return }
//      captureData.callback(.success(photoData))
//    }
//  }
//}
//
//extension DefaultPhotoCapturer {
//  private func process(_ photo: AVCapturePhoto, _ metadata: CaptureMetadata) -> PhotoData? {
//    guard
//      let data = photo.fileDataRepresentation(),
//      let image = UIImage(data: data),
//      let captureDevice = captureDevice
//    else { return nil }
//
//    let orientation = calculate(
//      given: captureDevice.orientation,
//      metadata.orientation
//    )
//    let newImage = UIImage(
//      cgImage: image.cgImage!,
//      scale: image.scale,
//      orientation: orientation
//    ).oriented
//
//    //let newCIImage = CIImage(image: newImage)!
//    let depthDataTypePreference = [kCVPixelFormatType_DepthFloat32, kCVPixelFormatType_DepthFloat16]
//    guard
//      let depthData = photo.depthData,
//      let dataType = depthData.availableDepthDataTypes.map({ OSType(truncating: $0) }).contains(preferenceOrder: depthDataTypePreference)
//    else {
//        return PhotoData(
//            depth: nil,
//            photo: newImage,
//            metadata: metadata
//        )
//    }
//
//    let depthPixelBuffer = depthData.converting(toDepthDataType: dataType).depthDataMap
//    depthPixelBuffer.normalize()
//
//    let ciimage = CIImage(cvPixelBuffer: depthPixelBuffer)
//    let depthImage = UIImage(
//      ciImage: ciimage,
//      scale: image.scale,
//      orientation: orientation
//    ).oriented
//
//    return PhotoData(
//      depth: depthImage,
//      photo: newImage,
//      metadata: metadata
//    )
//  }
//  
//  private func calculate(
//    given cameraSelection: CaptureDeviceSettings.Orientation,
//    _ deviceOrientation: UIDeviceOrientation
//  ) -> UIImage.Orientation {
//    switch deviceOrientation {
//    case .landscapeLeft: return cameraSelection == .back ? .up : .downMirrored
//    case .landscapeRight: return cameraSelection == .back ? .down : .upMirrored
//    case .portraitUpsideDown: return cameraSelection == .back ? .right : .leftMirrored
//    default: return cameraSelection == .back ? .right : .leftMirrored
//    }
//  }
//}
//
//extension Array where Element: Equatable {
//  func contains(preferenceOrder: [Element]) -> Element? {
//    for element in preferenceOrder {
//      guard let match = self.first(where: { $0 == element }) else { continue }
//      return match
//    }
//    return nil
//  }
//}
