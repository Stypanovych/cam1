import ImageProcessor
import CoreImage
import CombineSchedulers
import Combine
import UIKit

public typealias DazeFilter = (
  CIImage,
  FilteredImage.Metadata,
  FilteredImage.Parameters,
  InMemoryResources
) -> CIImage

public func filter(
  image: CIImage,
  metadata: FilteredImage.Metadata,
  parameters: FilteredImage.Parameters,
  inMemoryResources: InMemoryResources
) -> CIImage {
  let lutImage = inMemoryResources.lookup
  let leakImage = inMemoryResources.lightLeak
  let dustParticleImage = inMemoryResources.dust.particles.frame
  let dustHairImage = inMemoryResources.dust.hairs.frame
  let grainImage = inMemoryResources.grain
  let lutFilter =  lut(
    lutImage, // TODO: safe unwrap
    intensity: parameters.lookupIntensity
  )
  return image.filter {
    passthrough()
    glow(
      radius: .normalized(parameters.glowRadius / 200),
      intensity: parameters.glowOpacity,
      threshold: 1 - parameters.glowThreshold
    )
    //chromab(intensity: parameters.chromaScale / 40)
    chromab(intensity: parameters.chromaScale / 40)
    blur(radius: .normalized(parameters.blurRadius / 400))
    vignette(
      angleAtEdge: 80,
      intensity: parameters.vignetteIntensity
    )
    leak(
      leakImage,
        //.filter { lutFilter },
      intensity: parameters.lightLeakOpacity
    )
    lutFilter
    // stamp
    buildFilter {
      dateStamp(DateString.generate(
        image: $0,
        date: metadata.originDate,
        dateVisible: parameters.stampDateVisible,
        timeVisible: parameters.stampTimeVisible,
        font: {
          switch parameters.stampFont {
          case .digital: return UIFont.dazecam.digital.withSize($0).uiFont
          case .dot: return UIFont.dazecam.dot.withSize($0 * 0.88).uiFont
          }
        },
        color: parameters.stampColor
      ))
    }
    grain(
      overlay: grainImage,
      size: parameters.grainSize,
      intensity: parameters.grainOpacity
    )
    dust(
      //dustHairImage,
      dustParticleImage.filter { blend(dustHairImage, mode: .screen) },
      opacity: parameters.dustOpacity
    )
  }
}

struct DateString {
  static func generate(
    image: CIImage,
    date: Date,
    dateVisible: Bool,
    timeVisible: Bool,
    font: (CGFloat) -> UIFont,
    color: CGFloat
  ) -> NSAttributedString {
    print(color)
    return attributedString(
      for: image,
      string: string(
        date: date,
        dateVisible: dateVisible,
        timeVisible: timeVisible
      ),
      font: font,
      color: color
    )
  }
  
  private static func string(date: Date, dateVisible: Bool, timeVisible: Bool) -> String {
    var string: String = ""
    let locale: Locale = .current
    //let locale: Locale = try! .init(identifier: "en_US")
    if dateVisible {
      let dayMonth = (DateFormatter() ~~ {
        $0.dateFormat = DateFormatter.dateFormat(fromTemplate: "dM", options: 0, locale: locale)
      })
        .string(from: date)
        .replacingOccurrences(of: "/", with: "  ")
      let year = (DateFormatter() ~~ {
        $0.dateFormat = DateFormatter.dateFormat(fromTemplate: "yy", options: 0, locale: locale)
      })
        .string(from: date)
      string += (dayMonth + "  '" + year)
    }
    if timeVisible {
      if !string.isEmpty { string += "  " }
      let hourMin = (DateFormatter() ~~ {
        $0.dateFormat = DateFormatter.dateFormat(fromTemplate: "hh:mm", options: 0, locale: locale)
      })
        .string(from: date)
      string += hourMin
    }
    return string
  }

  private static func attributedString(
    for image: CIImage,
    string: String,
    font: (CGFloat) -> UIFont,
    color: CGFloat
  ) -> NSAttributedString {
    let fontSize = ImageUnit.normalized(0.0325)
    let fontSizePixels = fontSize.pixels(image.extent)
    return NSAttributedString(
      string: string,
      attributes: [
        NSAttributedString.Key.kern: (fontSizePixels / 4.0).pixelsToPoints(), // when it's 4 it crashes?
        NSAttributedString.Key.font: font(fontSizePixels.pixelsToPoints()),
        NSAttributedString.Key.foregroundColor: UIColor(
          red: 1.0,
          green: (1 - color) * 0.5,
          blue: (1 - color) * 0.125,
          alpha: 1.0
        ),
        //NSAttributedString.Key.foregroundColor: UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),
        //NSAttributedString.Key.backgroundColor: UIColor.black
      ]
    )
  }
}
