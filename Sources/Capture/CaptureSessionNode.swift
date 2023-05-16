//import Foundation
//import AVKit
//
//public class CaptureSessionNode {
//    private(set) var inputs: Inputs = Inputs()
//    private(set) var outputs: Outputs = Outputs()
//    
//    private let modifier: CaptureSessionModifier
//    
//    public var device: CaptureDevice? { inputs.captureInput }
//    
//    public init(modifier: CaptureSessionModifier) {
//        self.modifier = modifier
//    }
//    
//    struct Inputs {
//        var captureInput: AVBackedCaptureDevice?
//        var audioInput: AVCaptureDeviceInput?
//    }
//    
//    struct Outputs {
//        var photoOutput: AVCapturePhotoOutput?
//        var videoDataOutput: AVCaptureVideoDataOutput?
//        var audioDataOutput: AVCaptureAudioDataOutput?
//    }
//    
//    var layer: AVCaptureVideoPreviewLayer { modifier.layer }
//    
//    func add(output: AVCapturePhotoOutput) throws {
//        try modifier.add(output: output)
//        outputs.photoOutput = output
//    }
//    
//    func add(output: AVCaptureVideoDataOutput) throws {
//        try modifier.add(output: output)
//        outputs.videoDataOutput = output
//    }
//    
//    func add(output: AVCaptureAudioDataOutput) throws {
//        try modifier.add(output: output)
//        outputs.audioDataOutput = output
//    }
//    
//    func add(device: AVCaptureDevice, configure: () -> Void) throws -> CaptureDevice {
//        let newInput = try AVCaptureDeviceInput(device: device)
//        if let currentInput = inputs.captureInput?.backingDeviceInput {
//            try modifier.replace(oldInput: currentInput, with: newInput, configure: configure)
//        } else {
//            try modifier.add(input: newInput, configure: configure)
//        }
//        let captureDevice = AnalogCaptureDevice(deviceInput: newInput)
//        inputs.captureInput = captureDevice
//        return captureDevice
//    }
//    
//    func removeDevice() {
//        guard let device = inputs.captureInput?.backingDeviceInput else { return }
//        modifier.remove(input: device)
//        inputs.captureInput = nil
//    }
//    
//    func addAudioInput() throws {
//        if inputs.audioInput == nil,
//           let device = AVCaptureDevice.default(for: .audio),
//           let audioInput = try? AVCaptureDeviceInput(device: device
//        ) {
//            try modifier.add(input: audioInput, configure: { })
//            self.inputs.audioInput = audioInput
//        }
//    }
//    
//    func removeAudioInput() {
//        guard let audioInput = inputs.audioInput else { return }
//        modifier.remove(input: audioInput)
//        inputs.audioInput = nil
//    }
//    
//    func configure(with preset: AVCaptureSession.Preset) {
//        modifier.configure(with: preset)
//    }
//}
//
//extension CaptureSessionNode: Equatable {
//  public static func == (lhs: CaptureSessionNode, rhs: CaptureSessionNode) -> Bool {
//    lhs.inputs == rhs.inputs &&
//    lhs.outputs == rhs.outputs
//  }
//}
//
//extension CaptureSessionNode.Inputs: Equatable {
//  // TODO: device
//  public static func == (lhs: Self, rhs: Self) -> Bool {
//    lhs.audioInput == rhs.audioInput
//  }
//}
//extension CaptureSessionNode.Outputs: Equatable {}
