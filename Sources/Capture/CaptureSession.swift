//import Foundation
//import AVKit
//
//public struct CaptureState {
//  public var mode: CaptureMode
//  public var orientation: CaptureDeviceSettings.Orientation
//  
//  public init(mode: CaptureMode, orientation: CaptureDeviceSettings.Orientation) {
//      self.mode = mode
//      self.orientation = orientation
//  }
//  
//  public func map<U>(_ keyPath: WritableKeyPath<Self, U>, _ newValue: U) -> Self {
//    var copy = self
//    copy[keyPath: keyPath] = newValue
//    return copy
//  }
//}
//
//public class CaptureSessionSetuper {
//    private let modifier: CaptureSessionModifier
//    
//    public init(modifier: CaptureSessionModifier) {
//        self.modifier = modifier
//    }
//    
//    public func setup(with state: CaptureState) throws -> CaptureSession {
//        let photoOutput = AVCapturePhotoOutput()
//        let videoOutput = AVCaptureVideoDataOutput()
//        let audioOutput = AVCaptureAudioDataOutput()
//        //videoOutput.movieFragmentInterval = .invalid
//        let node = CaptureSessionNode(modifier: modifier)
//        try node.add(output: photoOutput)
//        try node.add(output: videoOutput)
//        try node.add(output: audioOutput)
//
//        modifier.startRunning()
//        
//        let captureSession = CaptureSession(node: node)
//        try captureSession.change { _ in [state] }
//        return captureSession
//    }
//}
//
//public enum CaptureSessionError: Swift.Error {
//    case sameDevice(CaptureDevice)
//    case notAvailable
//    case currentlyRecording
//}
//// modifies a CaptureSessionNode
//public class CaptureSession {
//    typealias Error = CaptureSessionError
//    public let node: CaptureSessionNode
//    private let chooser = CaptureDeviceChooser()
//    
//    private var captureState: CaptureState?
//    
//    init(node: CaptureSessionNode) {
//        self.node = node
//    }
//    
//    public func getPreview() throws -> CALayer {
//        let previewLayer = node.layer
//        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        //previewLayer.backgroundColor = UIColor.black.cgColor
//        previewLayer.connection?.videoOrientation = .portrait
//        return previewLayer
//    }
//    
//    public func configureAudioForRecording() {
//        let audioSession = AVAudioSession.sharedInstance()
//        //try? audioSession.setActive(false)
//        try? audioSession.setActive(false)
//        try? audioSession.setCategory(
//            .playAndRecord,
//            options: [.mixWithOthers, .defaultToSpeaker, .allowBluetoothA2DP, .allowAirPlay, .allowBluetooth]
//        )
//        try? audioSession.setActive(true)
//
//        try? node.addAudioInput()
//    }
//    
//    public func configureAudioForPlayback() {
//        node.removeAudioInput()
//
//        let audioSession = AVAudioSession.sharedInstance()
//        try? audioSession.setActive(false)
//        try? audioSession.setCategory(
//            .playback,
//            options: [.mixWithOthers, /*.allowAirPlay*/]
//        )
//        try? audioSession.setActive(true)
//    }
//
//    @discardableResult
//    public func change(state: (CaptureState?) -> [CaptureState]) throws -> CaptureDevice {
//        // find first state that works
//        let states = state(captureState)
//        guard let nextState = states.first(where: { chooser.captureDevice(for: $0.orientation, $0.mode) != nil })
//        else {
//            node.removeDevice()
//            captureState = states.first!
//            throw Error.notAvailable
//        }
//        let nextDevice = chooser.captureDevice(for: nextState.orientation, nextState.mode)!
//
//        guard let currentCaptureDevice = node.inputs.captureInput else {
//            return try add(device: nextDevice, with: nextState)
//        }
//        
//        let currentAVDevice = currentCaptureDevice.backingDeviceInput.device
//        guard nextDevice != currentAVDevice else { throw Error.sameDevice(currentCaptureDevice) }
//        // update hardware
//        let newCaptureDevice = try add(device: nextDevice, with: nextState)
//        
//        copySettingsFrom(currentCaptureDevice, to: newCaptureDevice)
//        return newCaptureDevice
//    }
//    
//    private func add(device: AVCaptureDevice, with state: CaptureState) throws -> CaptureDevice {
//        let newCaptureDevice = try node.add(device: device) {
//            configure(for: device)
//        }
//        state.mode.configure(node: node)
//        configure(for: state, device: device)
//        captureState = state
//        return newCaptureDevice
//    }
//}
//
//extension CaptureSession {
//    private func copySettingsFrom(_ oldDevice: CaptureDevice, to newDevice: CaptureDevice) {
//        // if newDevice has the capability then adjust based
//        if newDevice.capabilities.zoom { newDevice.adjust(zoom: 0) }
//        if newDevice.capabilities.flash { newDevice.adjust(flash: oldDevice.capabilities.flash ? oldDevice.flash : .off) }
//        //if newDevice.capabilities.focus { newDevice.adjust(focus: oldDevice.capabilities.focus ? oldDevice.focus : .init(level: 0, mode: .auto)) }
//    }
//    
//    private func configure(for device: AVCaptureDevice) {
//        let videoOutput = node.outputs.videoDataOutput!
//        guard let connection = videoOutput.connection(with: .video) else { return }
//        let orientation: AVCaptureVideoOrientation = .portrait
//        if connection.isVideoOrientationSupported && connection.videoOrientation != orientation { connection.videoOrientation = orientation }
//        connection.isVideoMirrored = connection.isVideoMirroringSupported && (device.position == .front)
//    }
//    
//    private func configure(for state: CaptureState, device: AVCaptureDevice) {
//        let output = node.outputs.photoOutput!
//        // Why iphone 8 fails?
//        guard output.isDepthDataDeliverySupported && (state.mode == .depth) else { return }
//        output.isDepthDataDeliveryEnabled = true
//        
//        let availableFormats = device.activeFormat.supportedDepthDataFormats
//        // iphone 8 only has disparity?
//        let formatPreference = [kCVPixelFormatType_DepthFloat32, kCVPixelFormatType_DepthFloat16]
//        for format in formatPreference {
//            guard let matchedFormat = availableFormats.first(where: { format == CMFormatDescriptionGetMediaSubType($0.formatDescription) })
//            else { continue }
//            try! device.configure { device.activeDepthDataFormat = matchedFormat }
//            break
//        }
//    }
//}
//
//extension CaptureSession: Equatable {
//  public static func == (lhs: CaptureSession, rhs: CaptureSession) -> Bool {
//    lhs.node == rhs.node &&
//    lhs.captureState == rhs.captureState
//  }
//}
//
//extension CaptureState: Equatable {
//  public static func == (lhs: Self, rhs: Self) -> Bool {
//    lhs.mode == rhs.mode &&
//    lhs.orientation == rhs.orientation
//  }
//}
