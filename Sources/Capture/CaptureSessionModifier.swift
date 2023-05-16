//import Foundation
//import AVKit
//
//public class CaptureSessionModifier {
//    let captureSession: AVCaptureSession
//    
//    public init(captureSession: AVCaptureSession) {
//        self.captureSession = captureSession
//    }
//
//    func add(input: AVCaptureDeviceInput, configure: () -> Void) throws {
//        try captureSession.configure {
//            guard captureSession.canAddInput(input) else { throw Error.cantAddInput }
//            captureSession.addInput(input)
//            configure()
//        }
//    }
//    
//    func remove(input: AVCaptureInput) {
//        captureSession.configure {
//            captureSession.removeInput(input)
//        }
//    }
//    
//    func replace(oldInput: AVCaptureInput, with newInput: AVCaptureInput, configure: () -> Void) throws {
//        try captureSession.configure {
//            captureSession.removeInput(oldInput)
//            guard captureSession.canAddInput(newInput) else { throw Error.cantAddInput }
//            captureSession.addInput(newInput)
//            configure()
//        }
//    }
//
//    func add(output: AVCaptureOutput) throws {
//        try captureSession.configure {
//            guard captureSession.canAddOutput(output) else { throw Error.cantAddOutput }
//            captureSession.addOutput(output)
//        }
//    }
//    
//    // call on background thread
//    func startRunning() {
//        captureSession.startRunning()
//    }
//    
//    var layer: AVCaptureVideoPreviewLayer { AVCaptureVideoPreviewLayer(session: captureSession) }
//    
//    func configure(with preset: AVCaptureSession.Preset) {
//        captureSession.configure {
//            guard captureSession.sessionPreset != preset else { return }
//            if captureSession.canSetSessionPreset(preset) {
//                captureSession.sessionPreset = preset
//            }
//        }
//    }
//    
//    enum Error: Swift.Error {
//        case cantAddInput
//        case cantAddOutput
//    }
//}
