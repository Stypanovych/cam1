import CoreGraphics
import UIKit

// MARK: - Transformation
public enum Transformation {
  public struct Rect {
    public let transform: (CGRect) -> CGRect

    public struct Size {
      public let transform: (CGRect) -> CGSize
    }

    public struct Position {
      public let transform: (CGRect) -> CGPoint
    }
  }
}

extension Transformation.Rect.Position {
  public static var same: Self {
    .init { $0.origin }
  }

  public static func constant(_ point: CGPoint) -> Self {
    .init { _ in point }
  }

  public static func offset(x: CGFloat, y: CGFloat) -> Self {
    same.offset(x: x, y: y)
  }

  public static func center(in rect: CGRect) -> Self {
    same.center(in: rect)
  }

  public func offset(x: CGFloat, y: CGFloat) -> Self {
    .init { rect in
      rect
        .replacing(transform(rect))
        .origin
        .offset(x: x, y: y)
    }
  }

  public func center(in rect: CGRect) -> Self {
    .init {
      $0
        .replacing(transform($0))
        .center(to: rect.center)
        .origin
    }
  }
}

extension Transformation.Rect.Size {
  public static var same: Self {
    .init { $0.size }
  }

  public static func constant(_ size: CGSize) -> Self {
    .init { _ in size }
  }

  public static func scalingBy(_ value: CGFloat) -> Self {
    .init { $0.size.scale(by: value) }
  }

  public static func scalingBy(x: CGFloat, y: CGFloat) -> Self {
    .init { $0.size.scaleBy(x: x, y: y) }
  }

  public static func fitting(area: CGFloat) -> Self {
    .init { rect in
      let factor = sqrt(area / rect.size.area)
      return rect.size.scale(by: factor)
    }
  }

  public static func filling(_ sizeToFill: CGSize) -> Self {
    .init { rect in
      let scaleX = sizeToFill.width / rect.size.width
      let scaleY = sizeToFill.height / rect.size.height
      return rect.size.scaleBy(x: scaleX, y: scaleY)
    }
  }

  public static func fittingAspect(_ sizeToFill: CGSize) -> Self {
    .init { rect in
      let scaleX = sizeToFill.width / rect.size.width
      let scaleY = sizeToFill.height / rect.size.height
      let factor = min(scaleX, scaleY)
      return rect.size.scale(by: factor)
    }
  }

  public static func fillingAspect(_ sizeToFill: CGSize) -> Self {
    .init { rect in
      let scaleX = sizeToFill.width / rect.size.width
      let scaleY = sizeToFill.height / rect.size.height
      let factor = max(scaleX, scaleY)
      return rect.size.scale(by: factor)
    }
  }
}

extension Transformation.Rect {
  public static var same: Self {
    .init { $0 }
  }

  public static func constant(_ rect: CGRect) -> Self {
    .init { _ in rect }
  }

  public static func size(_ sizeTransform: Size) -> Self {
    same.size(sizeTransform)
  }

  public static func position(_ originTransform: Position) -> Self {
    same.position(originTransform)
  }

  public func size(_ sizeTransform: Size) -> Self {
    .init { rect in
      let newRect = transform(rect)
      let size = sizeTransform.transform(newRect)
      return newRect.replacing(size)
    }
  }

  public func position(_ originTransform: Position) -> Self {
    .init { rect in
      let newRect = transform(rect)
      let origin = originTransform.transform(newRect)
      return newRect.replacing(origin)
    }
  }
}
