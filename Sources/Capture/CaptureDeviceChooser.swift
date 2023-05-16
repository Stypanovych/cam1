//import Foundation
//import AVKit
//
//struct CaptureDeviceChooser {
//    func captureDevice(for orientation: CaptureDeviceSettings.Orientation, _ mode: CaptureMode) -> AVCaptureDevice? {
//        let mediaType: AVMediaType = (mode == .depth) ? .depthData : .video
//        let deviceTypePriority: [AVCaptureDevice.DeviceType]
//        if #available(iOS 13.0, *) {
//             deviceTypePriority = [
//                .builtInWideAngleCamera,
//                .builtInTrueDepthCamera,
//                .builtInTripleCamera,
//                .builtInDualWideCamera,
//                .builtInDualCamera
//            ]
//        } else {
//             deviceTypePriority = [
//                .builtInWideAngleCamera,
//                .builtInTrueDepthCamera,
//                .builtInDualCamera
//            ]
//        }
//
//        let devices = AVCaptureDevice.DiscoverySession(
//            deviceTypes: deviceTypePriority,
//            mediaType: mediaType,
//            position: orientation.position
//        )
//        for deviceType in deviceTypePriority {
//            if let device = devices.devices.first(where: { $0.deviceType == deviceType }) {
//                //device.hasMediaType(.audio)
//                return device
//            }
//        }
//        return nil
//    }
//}
