#if DEBUG
import Foundation
import Engine
import Combine
import UIKit
import ComposableArchitecture

public let bundle = Bundle.module

public extension File.Pointer {
  static func image(named name: String) -> Self {
    let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "files")!
    return .init(url: url)
  }
}

public extension IdentifiedArray where Element == FilteredImage, ID == FilteredImage.ID {
  static func mock() -> Self {
    return [
      FilteredImage(
        id: UUID(),
        originalImagePath: .image(named: "photo1.jpg"),
        filteredImagePath: .image(named: "photo1.jpg"),
        thumbnailImagePath: .image(named: "photo1.jpg"),
        filterDate: Date(),
        metadata: .init(originDate: Date()),
        parameters: .empty,
        preset: nil
      ),
      FilteredImage(
        id: UUID(),
        originalImagePath: .image(named: "photo2.jpg"),
        filteredImagePath: .image(named: "photo2.jpg"),
        thumbnailImagePath: .image(named: "photo2.jpg"),
        filterDate: Date(),
        metadata: .init(originDate: Date()),
        parameters: .empty,
        preset: nil
      )
    ]
  }
}

public extension IdentifiedArray where Element == PhotoLibrary.Image, ID == PhotoLibrary.Image.ID {
  static func mock() -> Self {
    return [
      .named("photo1.jpg", index: 0),
      .named("photo2.jpg", index: 1)
    ]
  }
}

extension PhotoLibrary.Image {
  static func named(_ name: String, index: Int) -> Self {
    .init(
      id: UUID(),
      date: Date(),
      index: index,
      photoWithSize: { size in
        Future.deferred { photoPromise in
          photoPromise(.success(UIImage(contentsOfFile: File.Pointer.image(named: name).path)!))
        }
      }
    )
  }
//  static func stub() -> Self {
//    .init(
//      id: UUID(),
//      photoWithSize: { size in
//        Future.deferred { photoPromise in
//          photoPromise(.success(UIImage(color: .blue)!))
//        }
//      }
//    )
//  }
}
#endif
