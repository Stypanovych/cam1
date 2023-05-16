import UIKit
import SwiftUI
import DazeFoundation

//struct EmptyName {}
//struct EmptySize {}
//struct EmptyWeight {}
//
//public struct FontBuilder<Name, Size, Weight> {
//}
//
//extension FontBuilder where Name == EmptyName {
//  var avenir: FontBuilder<Avenir, Size, Weight> {  }
//}

public extension Theme.Font {
  struct Avenir {
    let name: String = "Avenir"
    var size: CGFloat = 13
    var weight: String = "Black"
    
    public var small: Avenir { update(self) { $0.size = 9 } }
    public var mid: Avenir { update(self) { $0.size = 11 } }
    public var large: Avenir { update(self) { $0.size = 13 } }
    
    public var medium: Avenir { update(self) { $0.weight = "medium" } }
    public var heavy: Avenir { update(self) { $0.weight = "Heavy" } }
    public var black: Avenir { update(self) { $0.weight = "Black" } }
    
    public var uiFont: UIFont { .init(name: name + "-" + weight, size: size)! }
  }
  
  struct Jost {
    let name: String = "Jost"
    var size: CGFloat = 13
    var weight: String = "Bold"
    
    public var small: Jost { update(self) { $0.size = 9 } }
    public var mid: Jost { update(self) { $0.size = 11 } }
    public var large: Jost { update(self) { $0.size = 13 } }
    
    public var medium: Jost { update(self) { $0.weight = "Regular" } }
    public var heavy: Jost { update(self) { $0.weight = "Medium" } }
    public var black: Jost { update(self) { $0.weight = "Bold" } }
    
    public var uiFont: UIFont { .init(name: name + "-" + weight, size: size)! }
  }
  
  struct Digital {
    let name = "DS-Digital-Italic"
    var size: CGFloat = 13
    
    public func withSize(_ value: CGFloat) -> Digital { update(self) { $0.size = value } }
    public var uiFont: UIFont { .init(name: name, size: size)! }
  }
  
  struct Dot {
    let name = "LEDDotMatrixRegular"
    var size: CGFloat = 13
    
    public func withSize(_ value: CGFloat) -> Dot { update(self) { $0.size = value } }
    public var uiFont: UIFont { .init(name: name, size: size)! }
  }
}

@dynamicMemberLookup
public class Theme: ObservableObject {
  public static let shared = Theme()
  
  @Published public var animation = Animation()
  @Published public var font = Font()
  @Published public var color = Color()
  @Published public var dimension = Dimension()
  @Published public var shadow = Shadow()
  
  public struct Animation {
    public let time: TimeInterval = 0.3
  }

  public struct Shadow {
    public let color = UIColor(hex: 0x242D2C)
    public let radius: CGFloat = 5
    
    public func apply(to view: UIView) {
      view.layer.shadowOffset = .zero
      view.layer.shadowColor = color.cgColor
      view.layer.shadowRadius = radius
      view.layer.shadowOpacity = 0.15
    }
  }

  public struct Font {
//    let name: String
//    let size: CGFloat
//    let weight: String
//
//    struct Sizes {
//      let small: CGFloat
//      let medium: CGFloat
//      let large: CGFloat
//    }
//
//    struct Weights {
//      let bold
//      let
//    }
    public let main = Jost()
    public let digital = Digital()
    public let dot = Dot()
    
//    public let title = UIFont(name: "Avenir-Heavy", size: 13)!
//    public let titleBold = UIFont(name: "Avenir-Black", size: 13)!
//    public let titleSmall = UIFont(name: "Avenir-Heavy", size: 9)!
//    public let titleSmallBold = UIFont(name: "Avenir-Black", size: 11)!
//    public let description = UIFont(name: "Avenir-Medium", size: 12)!
//    public let descriptionBold = UIFont(name: "Avenir-Black", size: 12)!
    public let kerning: CGFloat = 3.0
    
    // avenir.small.bold
    // avenir.size(number).bold
    // UIFont.dazecam.description.bold
    // .dazecam.description
    
//    private static func font(for uiFont: UIFont) -> SwiftUI.Font {
//      SwiftUI.Font(uiFont as CTFont)
//    }
  }

  public struct Color {
    public let dark = UIColor(hex: 0x242D2C)
    public let extraDark = UIColor(hex: 0x171615)
    public let light = UIColor(hex: 0xFFFBFA)
    public let shadowDark = UIColor(hex: 0x171615)
    public let red = UIColor(hex: 0xF37F8D)
    public let pink = UIColor(hex: 0xFFDEDE)
    public let logoDark = UIColor(hex: 0x10665F)
    public let teal = UIColor(hex: 0x2FCFC2)
  }

  public struct Dimension {
    public let unit: CGFloat = 10
    public var barHeight: CGFloat { 6 * unit }
    public var margins: CGFloat { 2 * unit }
    public var safeAreaInsets: UIEdgeInsets {
      UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero
    }
  }
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Animation, T>) -> T {
    return animation[keyPath: keyPath]
  }
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Font, T>) -> T {
    return font[keyPath: keyPath]
  }
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Color, T>) -> T {
    return color[keyPath: keyPath]
  }
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Dimension, T>) -> T {
    return dimension[keyPath: keyPath]
  }
}

public extension UIColor {
  static var dazecam: Theme.Color { Theme.shared.color }
}

public extension CGFloat {
  static var dazecam: Theme.Dimension { Theme.shared.dimension }
}


public extension UIColor {
  convenience init(red: Int, green: Int, blue: Int) {
    assert(red >= 0 && red <= 255, "Invalid red component")
    assert(green >= 0 && green <= 255, "Invalid green component")
    assert(blue >= 0 && blue <= 255, "Invalid blue component")
    
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
  }
  
  convenience init(hex: Int) {
    self.init(
      red: (hex >> 16) & 0xFF,
      green: (hex >> 8) & 0xFF,
      blue: hex & 0xFF
    )
  }
}

public extension UIColor {
  var swiftui: SwiftUI.Color {
    SwiftUI.Color(self)
  }
}

public extension UIFont {
  static var dazecam: Theme.Font { Theme.shared.font }
  
  var swiftui: SwiftUI.Font {
    SwiftUI.Font(self as CTFont)
  }
}


