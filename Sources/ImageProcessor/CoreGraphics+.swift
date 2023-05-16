import CoreGraphics
import UIKit

extension CGRect {
  var center: CGPoint {
    .init(
      x: origin.x + width / 2,
      y: origin.y + height / 2
    )
  }

  var area: CGFloat { size.area }
  var isPortrait: Bool { size.isPortrait }

  func center(to point: CGPoint) -> Self {
    .init(
      origin: .init(
        x: point.x - width / 2,
        y: point.y - height / 2
      ),
      size: size
    )
  }

  func replacing(_ origin: CGPoint) -> Self {
    .init(
      origin: origin,
      size: size
    )
  }

  func replacing(_ size: CGSize) -> Self {
    .init(
      origin: origin,
      size: size
    )
  }
}

extension CGSize {
  public var area: CGFloat { width * height }
  var isPortrait: Bool { height > width }

  func scale(by factor: CGFloat) -> Self {
    .init(
      width: factor * width,
      height: factor * height
    )
  }

  func scaleBy(x: CGFloat, y: CGFloat) -> Self {
    .init(
      width: x * width,
      height: y * height
    )
  }
}

extension CGPoint {
  func offset(x: CGFloat, y: CGFloat) -> Self {
    .init(
      x: self.x + x,
      y: self.y + y
    )
  }
}

public extension CGFloat {
  func pixelsToPoints() -> CGFloat {
    return self / UIScreen.main.scale
  }
  
  func pointsToPixels() -> CGFloat {
    return UIScreen.main.scale * self
  }
}
