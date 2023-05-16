import AVKit
import Combine
import DazeFoundation

// MARK: - CaptureSession
public class CaptureSession {
  let captureSession: AVCaptureSession

  public init(captureSession: AVCaptureSession) {
    self.captureSession = captureSession
  }

  func add(input: AVCaptureDeviceInput, configure: () -> Void) throws {
    try captureSession.configure {
      guard captureSession.canAddInput(input) else { throw Error.cantAddInput }
      captureSession.addInput(input)
      configure()
    }
  }

  func remove(input: AVCaptureInput) {
    captureSession.configure {
      captureSession.removeInput(input)
    }
  }

  func replace(oldInput: AVCaptureInput, with newInput: AVCaptureInput, configure: () -> Void) throws {
    try captureSession.configure {
      captureSession.removeInput(oldInput)
      guard captureSession.canAddInput(newInput) else { throw Error.cantAddInput }
      captureSession.addInput(newInput)
      configure()
    }
  }

  func add(output: AVCaptureOutput) throws {
    try captureSession.configure {
      guard captureSession.canAddOutput(output) else { throw Error.cantAddOutput }
      captureSession.addOutput(output)
    }
  }

  /// call on background thread
  func startRunning() {
    captureSession.startRunning()
  }

  /// call on background thread
  func stopRunning() {
    captureSession.stopRunning()
  }

  func createLayer() -> AVCaptureVideoPreviewLayer {
    AVCaptureVideoPreviewLayer(session: captureSession)
  }

  func configure(with preset: AVCaptureSession.Preset) {
    captureSession.configure {
      guard captureSession.sessionPreset != preset else { return }
      if captureSession.canSetSessionPreset(preset) {
        captureSession.sessionPreset = preset
      }
    }
  }

  enum Error: Swift.Error {
    case cantAddInput
    case cantAddOutput
  }
}

// MARK: - CaptureSessionNode
public class CaptureSessionNode {
  typealias Device = AVCaptureDevice
  typealias Input = AVCaptureDeviceInput
  typealias Output = AVCapturePhotoOutput

  private(set) var captureDevice: CaptureDevice?
  private(set) var device: Device?
  private(set) var input: Input?
  private(set) var output: Output

  private let session: CaptureSession

  public init(
    session: CaptureSession,
    output: AVCapturePhotoOutput
  ) throws {
    self.session = session
    self.output = output
    try add(output: output)
  }

  func createLayer() -> AVCaptureVideoPreviewLayer {
    session.createLayer() ~~ {
      $0.videoGravity = AVLayerVideoGravity.resizeAspectFill
      $0.backgroundColor = UIColor.black.cgColor
      $0.connection?.videoOrientation = .portrait
    }
  }

  func start(device: AVCaptureDevice) throws -> CaptureDevice {
    guard !session.captureSession.isRunning else { throw Error.sessionAlreadyRunning }
    let captureDevice = try change(device: device, configure: {})
    session.startRunning()
    return captureDevice
  }

  func stop() {
    guard session.captureSession.isRunning else { return }
    session.stopRunning()
  }

  private func add(output: Output) throws {
    try session.add(output: output)
    self.output = output
  }

  func change(device: Device, configure: () -> Void) throws -> CaptureDevice {
    let newInput = try AVCaptureDeviceInput(device: device)
    if let oldInput = input {
      try session.replace(
        oldInput: oldInput,
        with: newInput,
        configure: configure
      )
    } else {
      try session.add(
        input: newInput,
        configure: configure
      )
    }
    self.device = device
    input = newInput
    captureDevice = CaptureDevice(deviceInput: newInput)
    return captureDevice!
  }

  func configure(with preset: AVCaptureSession.Preset) {
    session.configure(with: preset)
  }

  enum Error: Swift.Error {
    case sessionAlreadyRunning
  }
}

// MARK: - CaptureDevice
public class CaptureDevice {
  private let device: AVCaptureDevice

//  private var minZoom: CGFloat { device.minAvailableVideoZoomFactor }
//  private var maxZoom: CGFloat { device.maxAvailableVideoZoomFactor }

//  public var zoom: Camera.Settings.Zoom {
//    (device.videoZoomFactor - minZoom) / (maxZoom - minZoom)
//  }

  public private(set) var flash: Camera.Settings.Flash = .off

  public var orientation: Camera.Settings.Orientation {
    device.position
  }

  public init(deviceInput: AVCaptureDeviceInput) {
    device = deviceInput.device
  }

//  public func adjust(zoom: Camera.Settings.Zoom) {
//    do {
//      try device.configure {
//        let zoomFactor = minZoom + pow(zoom, 2) * (maxZoom - minZoom)
//        device.videoZoomFactor = zoomFactor
//      }
//    } catch {
//      print(error)
//    }
//  }

  public func adjust(flash: Camera.Settings.Flash) {
    self.flash = flash
  }
}
