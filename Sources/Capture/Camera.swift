import AVKit
import Combine
import DazeFoundation
import ComposableArchitecture
//import Lib

// MARK: - Camera
public struct Camera {
  public var turnOn: (Camera.Settings, AnySchedulerOf<DispatchQueue>) -> AnyPublisher<Interface, Error>
  public var turnOff: () -> Void

  public struct Settings: Equatable {
    public var flash: Flash
    public var orientation: Orientation
    
    public init(
      flash: Flash,
      orientation: Orientation
    ) {
      self.flash = flash
      self.orientation = orientation
    }
    
    public enum Flash {
      case on
      case off
    }

    public typealias Orientation = AVCaptureDevice.Position
    //public typealias Zoom = CGFloat
  }

  public struct Interface {
    public var preview: CALayer
    public var capture: () -> AnyPublisher<CaptureData, Never>
    public var adjustOrientation: (Camera.Settings.Orientation) -> Camera.Settings
    public var adjustFlash: (Camera.Settings.Flash) -> Camera.Settings
    //public var adjustZoom: (Settings.Zoom) -> Void
  }

  public struct CaptureData: Equatable {
    public let photo: UIImage
    public let metadata: Metadata
    //public let exifData: ExifData

    public struct Metadata: Equatable {
      public let date: Date
      public let orientation: UIDeviceOrientation
      public let flash: Camera.Settings.Flash
    }

    public static var empty: Self {
      .init(
        photo: UIImage(),
        metadata: .init(date: Date(), orientation: .portrait, flash: .off)
        //exifData: [:]
      )
    }
  }
}

public extension Camera {
  private static func device(for orientation: Camera.Settings.Orientation) -> AVCaptureDevice? {
    AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera],
      mediaType: .video,
      position: orientation
    ).devices.first
  }
  
  static let live: Self = {
    let captureSession = AVCaptureSession()
    let session = CaptureSession(captureSession: captureSession)
    let node = try! CaptureSessionNode(
      session: session,
      output: AVCapturePhotoOutput()
    ) ~~ {
      $0.configure(with: .photo)
    }

    func turnOn(cameraSettings: Camera.Settings, scheduler: AnySchedulerOf<DispatchQueue>) -> (CaptureDevice, PhotoCapturer) {
      let photoCapturer = PhotoCapturer(
        node: node,
        scheduler: scheduler // TODO
      )
      let avDevice = device(for: cameraSettings.orientation)!
      var device = try! node.start(device: avDevice)
      return (device, photoCapturer)
    }
    
    func interface(for device: CaptureDevice, photoCapturer: PhotoCapturer) -> Interface {
      var device = device
      return Interface(
        preview: node.createLayer(), // must be called on main thread
        capture: {
          Future { promise in
            photoCapturer.capturePhoto(callback: promise)
          }
          .replaceError(with: .empty)
          .eraseToAnyPublisher()
        },
        adjustOrientation: { orientation in
          let flash = device.flash
          device = try! node.change(device: Self.device(for: orientation)!, configure: {})
          device.adjust(flash: flash)
          return .init(flash: device.flash, orientation: device.orientation)
        },
        adjustFlash: { flash in
          device.adjust(flash: flash)
          return .init(flash: device.flash, orientation: device.orientation)
        }
      )
    }
    
    return Camera(
      turnOn: { cameraSettings, scheduler in
        Future.deferred { promise in
          if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            promise(.success(()))
          } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
              DispatchQueue.main.async {
                guard granted else { return promise(.failure(GenericError("request denied"))) }
                promise(.success(()))
              }
            }
          }
        }
        .receive(on: scheduler)
        .map { turnOn(cameraSettings: cameraSettings, scheduler: scheduler) }
        .receive(on: DispatchQueue.main)
        .map { interface(for: $0, photoCapturer: $1) }
        .eraseToAnyPublisher()
      },
      turnOff: {
        node.stop()
      }
    )
  }()
}

#if DEBUG
public extension Camera {
  static func noop(success: Bool) -> Self {
    .init(
      turnOn: { _, _ in
        guard success else { return .fail(GenericError("denied access")) }
        return Just(Interface(
          preview: CALayer() ~~ { $0.backgroundColor = UIColor.black.cgColor },
          capture: {
            Future { promise in
              promise(.success(.empty))
            }
            .eraseToAnyPublisher()
          },
          adjustOrientation: { .init(flash: .off, orientation: $0) },
          adjustFlash: { .init(flash: $0, orientation: .back) }
        ))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
      },
      turnOff: {}
    )
  }
}
#endif
