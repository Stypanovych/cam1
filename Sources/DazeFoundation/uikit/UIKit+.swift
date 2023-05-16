import UIKit

public extension UIView {
  var isVisible: Bool {
    get { !isHidden }
    set {
      isHidden = !newValue
      alpha = newValue ? 1 : 0
    }
  }
}

public extension UIImage {
  convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
    let rect = CGRect(origin: .zero, size: size)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
    color.setFill()
    UIRectFill(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    guard let cgImage = image?.cgImage else { return nil }
    self.init(cgImage: cgImage)
  }
  
  func scaleToFit(_ sizeToFit: CGSize) -> UIImage {
    let scaleX = sizeToFit.width / size.width
    let scaleY = sizeToFit.height / size.height
    let factor = min(scaleX, scaleY)
    let newSize = CGSize(
      width: size.width * factor,
      height: size.height * factor
    )
    let image = UIGraphicsImageRenderer(size: newSize).image { _ in
      draw(in: CGRect(origin: .zero, size: newSize))
    }
    return image.withRenderingMode(renderingMode)
    
//    let scale = size.height / size.height
//    let newWidth = size.width * scale
//    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: size.height))
//    draw(in: CGRect(x: 0, y: 0, width: newWidth, height: size.height))
//    let newImage = UIGraphicsGetImageFromCurrentImageContext()
//    UIGraphicsEndImageContext()
//    return
  }
}
