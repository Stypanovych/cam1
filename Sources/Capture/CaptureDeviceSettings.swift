//import Foundation
//import AVKit
//
//// change this to capture device capabilities?
//public enum CaptureMode: SessionConfigurer {
//    case photo
//    case video
//    case depth
//    
//    func configure(node: CaptureSessionNode) {
//        switch self {
//        case .depth, .photo: node.configure(with: .photo)
//        case .video: node.configure(with: .high)
//        }
//    }
//}
//
//protocol SessionConfigurer {
//    func configure(node: CaptureSessionNode)
//}
//
//public struct CaptureDeviceSettings {
//    public struct Capabilities {
//        public let zoom: Bool
//        public let focus: Bool
//        public let flash: Bool
//    }
//    
//    public enum Orientation {
//        case front
//        case back
//    }
//    
//    public typealias Zoom = CGFloat
//    
//    public struct Focus {
//        public let level: CGFloat
//        public let mode: Mode
//        
//        public init(level: CGFloat, mode: Mode) {
//            self.level = level
//            self.mode = mode
//        }
//        
//        public enum Mode {
//            case auto
//            case manual
//        }
//    }
//    
//    public enum Exposure {
//        case `default`
//        case custom(Settings)
//        
//        public struct Settings {
//            public let duration: ClosedRange<CMTime>
//            public let iso: Float
//            
//            public init(duration: ClosedRange<CMTime>, iso: Float) {
//                self.duration = duration
//                self.iso = iso
//            }
//        }
//    }
//    
//    public enum Flash {
//        case on
//        case off
//    }
//}
//
//extension CaptureDeviceSettings.Orientation: Togglable {
//    public var position: AVCaptureDevice.Position {
//        switch self {
//        case .back: return .back
//        case .front: return .front
//        }
//    }
//    
//    public func toggled() -> Self {
//        switch self {
//        case .back: return .front
//        case .front: return .back
//        }
//    }
//}
//
//extension CaptureDeviceSettings.Flash: Togglable {
//    func toggled() -> Self {
//        switch self {
//        case .off: return .on
//        case .on: return .off
//        }
//    }
//    
//    public var bool: Bool { self == .on }
//    
//    var mode: AVCaptureDevice.FlashMode {
//        switch self {
//        case .off: return .off
//        case .on: return .on
//        }
//    }
//}
//
//protocol Togglable {
//    func toggled() -> Self
//}
