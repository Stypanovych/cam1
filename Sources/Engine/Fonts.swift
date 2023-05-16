import Foundation
import CoreText
import UIKit

func loadFontWith(name: String, type: String) {
  let pathForResourceString = Bundle.module.path(forResource: name, ofType: type)
  let fontData = NSData(contentsOfFile: pathForResourceString!)
  let dataProvider = CGDataProvider(data: fontData!)
  let fontRef = CGFont(dataProvider!)
  var errorRef: Unmanaged<CFError>? = nil

  if (CTFontManagerRegisterGraphicsFont(fontRef!, &errorRef) == false) {
    NSLog("Failed to register font - register graphics font failed - this font may have already been registered in the main bundle.")
  }
}

public func registerAllFonts() {
//  loadFontWith(name: "Brandon_blk", type: "otf")
//  loadFontWith(name: "Brandon_bld", type: "otf")
//  loadFontWith(name: "Brandon_med", type: "otf")
//  loadFontWith(name: "Brandon_reg", type: "otf")

  //loadFontWith(name: "DS-DIGI", type: "TTF")
  //loadFontWith(name: "DS-DIGIB", type: "TTF")
  loadFontWith(name: "DS-DIGII", type: "ttf")
  loadFontWith(name: "Dot-Matrix", type: "ttf")
  loadFontWith(name: "Jost-Bold", type: "ttf")
  loadFontWith(name: "Jost-Medium", type: "ttf")
  loadFontWith(name: "Jost-Regular", type: "ttf")
  //loadFontWith(name: "DS-DIGIT", type: "TTF")
//  for family in UIFont.familyNames {
//
//    let sName: String = family as String
//    print("family: \(sName)")
//
//    for name in UIFont.fontNames(forFamilyName: sName) {
//      print("name: \(name as String)")
//    }
//  }
  //loadFontWith(name: "Dot-Matrix", type: "ttf")
}
