//import Foundation
//import AVKit
//
//public protocol CaptureDevice {
//    var capabilities: CaptureDeviceSettings.Capabilities { get }
//    var zoom: CaptureDeviceSettings.Zoom { get }
//    var focus: CaptureDeviceSettings.Focus { get }
//    var flash: CaptureDeviceSettings.Flash { get }
//    var orientation: CaptureDeviceSettings.Orientation { get }
//    func adjust(zoom: CaptureDeviceSettings.Zoom)
//    func adjust(focus: CaptureDeviceSettings.Focus)
//    func adjust(flash: CaptureDeviceSettings.Flash)
//    func adjust(fps: CGFloat)
//    //func adjust(exposureDuration: CameraSettings.Exposure)
//    func activateTorchIfNeeded()
//    func deactivateTorchIfNeeded()
//}
//
//internal typealias AVBackedCaptureDevice = CaptureDevice & AVBacked
//
//internal protocol AVBacked {
//    var backingDeviceInput: AVCaptureDeviceInput { get }
//}
//
//public class AnalogCaptureDevice: NSObject, CaptureDevice {
//    public var capabilities: CaptureDeviceSettings.Capabilities {
//        return .init(
//            zoom: device.minAvailableVideoZoomFactor != device.maxAvailableVideoZoomFactor,
//            focus: device.isLockingFocusWithCustomLensPositionSupported,
//            flash: device.hasFlash || device.hasTorch
//        )
//    }
//    
//    let backingDeviceInput: AVCaptureDeviceInput
//    @objc private let device: AVCaptureDevice
//    
//    private var minZoom: CGFloat { device.minAvailableVideoZoomFactor }
//    private var maxZoom: CGFloat { min(3, device.maxAvailableVideoZoomFactor) }
//    
//    public var zoom: CaptureDeviceSettings.Zoom {
//        guard capabilities.zoom else { return 0 }
//        return (device.videoZoomFactor - minZoom) / (maxZoom - minZoom)
//    }
//    
//    public private(set) var flash: CaptureDeviceSettings.Flash = .off
//    
//    public var orientation: CaptureDeviceSettings.Orientation {
//        switch device.position {
//        case .front: return .front
//        default: return .back
//        }
//    }
//    
//    public var focus: CaptureDeviceSettings.Focus {
//        switch device.focusMode {
//        case .continuousAutoFocus: return .init(level: CGFloat(device.lensPosition), mode: .auto)
//        default: return .init(level: CGFloat(device.lensPosition), mode: .manual)
//        }
//    }
//    
//    private var exposureOffsetObservation: NSKeyValueObservation? = nil
//    
//    public init(deviceInput: AVCaptureDeviceInput) {
//        self.backingDeviceInput = deviceInput
//        self.device = deviceInput.device
//        super.init()
//    }
//    
//    public func adjust(focus: CaptureDeviceSettings.Focus) {
//        guard capabilities.focus else { return }
//        do {
//            try device.configure {
//                switch focus.mode {
//                case .auto: device.focusMode = .continuousAutoFocus
//                case .manual: device.setFocusModeLocked(lensPosition: Float(focus.level), completionHandler: nil)
//                }
//            }
//        } catch let error {
//            print(error)
//        }
//    }
//    
//    public func adjust(zoom: CaptureDeviceSettings.Zoom) {
//        guard capabilities.zoom else { return }
//        do {
//            try device.configure {
//                let zoomFactor = minZoom + pow(zoom, 4) * (maxZoom - minZoom)
//                //device.ramp(toVideoZoomFactor: zoomFactor, withRate: 0.1)
//                device.videoZoomFactor = zoomFactor
//            }
//        } catch let error {
//            print(error)
//        }
//    }
//    
//    public func adjust(flash: CaptureDeviceSettings.Flash) {
//        self.flash = flash
//    }
//    
//    public func adjust(fps: CGFloat) {
//        do {
//            try device.configure {
//                var supported = false
//                for range in device.activeFormat.videoSupportedFrameRateRanges {
//                    guard (range.minFrameRate...range.maxFrameRate).contains(Float64(fps)) else { continue }
//                    supported = true
//                    break
//                }
//                guard supported else { return }
//                print(fps)
//                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
//                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
//            }
//        } catch let error {
//            print(error)
//        }
//    }
//    
////    public func adjust(exposureDuration: CameraSettings.Exposure) {
////        try! device.configure {
////            device.setExposureTargetBias(-0.5, completionHandler: nil)
////        }
//        
////        try! device.configure {
////            device.setWhiteBalanceModeLocked(with: .init(redGain: 1, greenGain: 1, blueGain: 1), completionHandler: nil)
////        }
//        
////        try! device.configure {
////            guard case .custom(let settings) = exposureDuration else {
////                exposureOffsetObservation = nil
////                return device.exposureMode = .continuousAutoExposure
////            }
////            observeExposureOffset(settings: settings)
////        }
////    }
//    
////    private func observeExposureOffset(settings: CameraSettings.Exposure.Settings) {
////        exposureOffsetObservation = observe(\.device.exposureTargetOffset) { (object, change) in
////
////            let shutterSpeedRange = settings.duration.clamped(to: object.device.activeFormat.minExposureDuration...object.device.activeFormat.maxExposureDuration)
////            let shutterSpeed = pow(2, Double(-object.device.exposureTargetOffset)) * object.device.exposureDuration.seconds
////            let targetShutterSpeed = CMTime(
////                seconds: shutterSpeed,
////                preferredTimescale: Int32(NSEC_PER_SEC)
////            )
////            let clampedShutterSpeed = targetShutterSpeed.clamped(to: shutterSpeedRange)
////            //print(clampedShutterSpeed.seconds)
////            try! object.device.configure {
////                object.device.setExposureModeCustom(
////                    duration: clampedShutterSpeed,
////                    iso: settings.iso.clamped(to: object.device.activeFormat.minISO...object.device.activeFormat.maxISO),
////                    completionHandler: nil
////                )
////            }
////        }
////    }
//    
//    public func activateTorchIfNeeded() {
//        guard flash.bool && device.hasTorch && device.isTorchModeSupported(.on) && !device.isTorchActive else { return }
//        try? device.configure {
//            try device.setTorchModeOn(level: 1.0)
//        }
//    }
//    
//    public func deactivateTorchIfNeeded() {
//        guard device.isTorchActive else { return }
//        try? device.configure {
//            device.torchMode = .off
//        }
//    }
//}
//
//extension AnalogCaptureDevice: AVBacked { }
