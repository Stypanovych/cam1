import CoreGraphics

// MARK: - ImageUnit
/// The `ImageUnit` type provides a convenient abstraction to create image units other than just pixels.
///
/// To illustrate why this is necessary, consider 2 of the exact same image, except one is 100x100 and one is 1000x1000.
///
/// If we blurred each image by 10 pixels using `ImageUnit.pixels(10)`, the resulting images would would different - the 1000x1000 one appearing much less blurred.
///
/// Now, if we used `ImageUnit.normalized(0.1)`, then both images would be blurred relative to their respective sizes, so both resulting images would look the same.
public struct ImageUnit {
  public let pixels: (_ extent: CGRect) -> CGFloat
}

extension ImageUnit {
  public static func pixels(_ value: CGFloat) -> Self {
    .init { _ in
      value
    }
  }

  /// Normalized side length
  ///
  /// a value of 1 corresponds to to the pixel length of the side of a square with the same area as the input rect
  public static func normalized(_ value: CGFloat) -> Self {
    .init { extent in
      value * sqrt(extent.area)
    }
  }
}

// MARK: - RotationUnit
public struct RotationUnit {
  public let radians: (CGRect) -> CGFloat
}

extension RotationUnit {
  public static func degrees(_ value: CGFloat) -> Self {
    .init { _ in value * .pi / 180 }
  }

  public static func radians(_ value: CGFloat) -> Self {
    .init { _ in value }
  }

  public static func byMatchingOrientation(_ matchRect: CGRect) -> Self {
    .init { rect in
      (rect.isPortrait != matchRect.isPortrait)
        ? RotationUnit.degrees(90).radians(rect)
        : RotationUnit.degrees(0).radians(rect)
    }
  }
}
