import CoreImage
import UIKit

public extension CIImage {
  static func blank(color: CIColor = .black, size: CGSize) -> CIImage {
    return CIImage(color: color).cropped(to: CGRect(origin: .zero, size: size))
  }
  
  static func text(string: NSAttributedString) -> CIImage {
    UIGraphicsBeginImageContextWithOptions(string.size(), false, 0)
    string.draw(at: .zero)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return CIImage(cgImage: newImage!.cgImage!)
  }
}
