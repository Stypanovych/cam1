import Foundation
import AVKit

extension AVCaptureSession {
  func configure(closure: () throws -> Void) rethrows {
    beginConfiguration()
    try closure()
    commitConfiguration()
  }
}

extension AVCaptureDevice {
  func configure(closure: () throws -> Void) throws {
    try lockForConfiguration()
    try closure()
    unlockForConfiguration()
  }
}

extension UIImage {
  var oriented: UIImage {
    UIGraphicsBeginImageContext(size)
    draw(at: .zero)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage ?? self
  }
}

extension CVPixelBuffer {
  var width: Int { return CVPixelBufferGetWidth(self) }
  var height: Int { return CVPixelBufferGetHeight(self) }
  
  func buffer<T>() -> UnsafeMutablePointer<T> {
      return unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<T>.self)
  }
  
  func accessPixels(with function: () -> Void) {
      CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
      function()
      CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
  }
  
  func normalize() {
    accessPixels {
      let floatBuffer: UnsafeMutablePointer<Float> = buffer()

      var minPixel: Float = Float.greatestFiniteMagnitude
      var maxPixel: Float = -minPixel

      floatBuffer.apply(width: width, height: height) {
        minPixel = min($0, minPixel)
        maxPixel = max($0, maxPixel)
        return $0
      }

      let range = maxPixel - minPixel
      floatBuffer.apply(width: width, height: height) { return ($0 - minPixel) / range }
    }
  }
}

extension UnsafeMutablePointer {
  func apply(width: Int, height: Int, _ function: (Pointee) -> Pointee) {
    for y in 0 ..< height {
      for x in 0 ..< width {
        let pixel = self[y * width + x]
        self[y * width + x] = function(pixel)
      }
    }
  }
}
