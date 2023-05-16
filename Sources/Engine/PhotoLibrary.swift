import Photos
import UIKit
import Combine

//public struct EngineError: Error {
//  public let description: String
//}

//public typealias LazyImage = Future<UIImage, LazyImageError>
public typealias Authorization = AnyPublisher<Bool, Never>

public struct LazyImage<Value: Identifiable & Hashable>: Hashable {
  public let value: Value
  public let future: AnyPublisher<UIImage, GenericError>
  
  public init(
    value: Value,
    future: AnyPublisher<UIImage, GenericError>
  ) {
    self.value = value
    self.future = future
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
  
  public static func == (lhs: LazyImage, rhs: LazyImage) -> Bool {
    return lhs.value == rhs.value
  }
}

//public struct LazyImageError: Error {
//  public let reason: String
//}
public extension PhotoLibrary.Image {
  func lazyImage(size: Size) -> LazyImage<PhotoLibrary.Image> {
    return .init(value: self, future: photoWithSize(size))
  }
}

public extension PhotoLibrary.Album {
  func lazyImage(size: PhotoLibrary.Image.Size) -> LazyImage<PhotoLibrary.Album> {
    return .init(value: self, future: thumbnail(size))
  }
}

extension PhotoLibrary.Image: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  public static func == (lhs: PhotoLibrary.Image, rhs: PhotoLibrary.Image) -> Bool {
    return lhs.id == rhs.id
  }
}

extension PhotoLibrary.Album: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  public static func == (lhs: PhotoLibrary.Album, rhs: PhotoLibrary.Album) -> Bool {
    return lhs.id == rhs.id
  }
}

public struct PhotoLibrary {
  public struct Album: Identifiable {
    public let id: AnyHashable
    public let name: String
    public let size: Int
    public let thumbnail: (Image.Size) -> AnyPublisher<UIImage, GenericError>
    public let images: () -> [Image]
    
    public init(
      id: AnyHashable,
      name: String,
      size: Int,
      thumbnail: @escaping (Image.Size) -> AnyPublisher<UIImage, GenericError>,
      images: @escaping () -> [Image]
    ){
      self.id = id
      self.name = name
      self.size = size
      self.thumbnail = thumbnail
      self.images = images
    }
  }
  
  public struct Image: Identifiable {
    public let id: AnyHashable
    public let index: Int
    public let date: Date
    public let photoWithSize: (Size) -> AnyPublisher<UIImage, GenericError>
    
    public init(
      id: AnyHashable,
      date: Date,
      index: Int,
      photoWithSize: @escaping (Size) -> AnyPublisher<UIImage, GenericError>
    ) {
      self.id = id
      self.date = date
      self.index = index
      self.photoWithSize = photoWithSize
    }
    
    public enum Size {
      case full
      case custom(CGSize)
      
      func sizeWithFull(as size: CGSize) -> CGSize {
        switch self {
        case .full: return size
        case .custom(let customSize): return customSize
        }
      }
    }
  }
  
  public let authorize: Authorization
  public let fetch: () -> [Album]
}

extension PhotoLibrary {
  public static let photos: PhotoLibrary = .init(
    authorize: Deferred {
      Future<Bool, Never> { promise in
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
          promise(.success(true))
        case .notDetermined, .denied, .restricted, .limited:
          PHPhotoLibrary.requestAuthorization { status in
            promise(.success(status == .authorized))
          }
        default:
          promise(.success(false))
        }
      }
    }.eraseToAnyPublisher(),
    fetch: fetchCollections
  )

  private static func image(asset: PHAsset, index: Int) -> Image {
    let photoWithSize = { (size: Image.Size) in
      Deferred { () -> Future<UIImage, GenericError> in
        switch size {
        case .full: return fullSizeImage(asset: asset)
        case let .custom(cgsize): return customSizeImage(asset: asset, size: cgsize)
        }
      }.eraseToAnyPublisher()
    }
    return Image(
      id: asset,
      date: asset.creationDate ?? asset.modificationDate ?? Date(),
      index: index,
      photoWithSize: photoWithSize
    )
  }
  
  private static func fullSizeImage(asset: PHAsset) -> Future<UIImage, GenericError> {
    let requestOptions = PHImageRequestOptions() ~~ {
      $0.isNetworkAccessAllowed = true
      $0.isSynchronous = true
      $0.deliveryMode = .highQualityFormat
      $0.resizeMode = .none
    }
    let imageManager = PHImageManager.default()
    return Future<UIImage, GenericError> { promise in
      imageManager.requestImage(
        for: asset,
        targetSize: PHImageManagerMaximumSize,
        contentMode: .default,
        options: requestOptions
      ) { image, info in
        guard let image = image else { return promise(.failure(.init("no image"))) }
        promise(.success(image))
      }
    }
  }
  
  private static func customSizeImage(asset: PHAsset, size: CGSize) -> Future<UIImage, GenericError> {
    let requestOptions = PHImageRequestOptions() ~~ {
      $0.isNetworkAccessAllowed = true
      $0.isSynchronous = true // TODO: background thread
      $0.deliveryMode = .opportunistic
//      $0.progressHandler = { progress, error, finished, info in
//
//      }
    }
    let imageManager = PHImageManager.default()
    return Future<UIImage, GenericError> { promise in
      imageManager.requestImage(
        for: asset,
        targetSize: size,
        contentMode: .aspectFill,
        options: requestOptions
      ) { (image, dict) in
        //print("in cloud \(dict?[PHImageResultIsInCloudKey])")
        guard let image = image else { return promise(.failure(.init("Request image failed"))) }
        promise(.success(image))
      }
    }
  }
  
  private static func fetchCollections() -> [Album] {
    func album(for assetCollection: PHAssetCollection) -> Album? {
      let assets = PHAsset.fetchAssets(in: assetCollection, options: nil)
      guard assets.count > 0 else { return nil }
      return .init(
        id: assetCollection,
        name: assetCollection.localizedTitle ?? "UNKNOWN",
        size: assets.count,
        thumbnail: { size in
          guard assets.count > 0 else {
            let black = UIImage(color: .black, size: size.sizeWithFull(as: .init(width: 500, height: 500)))!
            return Just(black).setFailureType(to: GenericError.self).eraseToAnyPublisher()
          }
          let firstAsset = assets.object(at: assets.count - 1)
          return Deferred { () -> Future<UIImage, GenericError> in
            switch size {
            case .full: return fullSizeImage(asset: firstAsset)
            case let .custom(cgsize): return customSizeImage(asset: firstAsset, size: cgsize)
            }
          }.eraseToAnyPublisher()
        },
        images: {
          return (0 ..< assets.count)
            .map { image(asset: assets.object(at: $0), index: $0) }
        }
      )
    }
    
    let cameraRoll = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
    let favorites = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil)
    let fetchResult = PHAssetCollection.fetchAssetCollections(
      with: .album,
      subtype: .any,
      options: PHFetchOptions() ~~ {
        $0.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
      }
    )
    
    let smartAlbums = [cameraRoll.firstObject, favorites.firstObject]
      .compactMap { $0 }
      .compactMap { album(for: $0) }
    let albums = (0 ..< fetchResult.count).compactMap { index in
      album(for: fetchResult.object(at: index))
    }
    return smartAlbums + albums
  }
}

#if DEBUG
public extension PhotoLibrary {
  static func mock(authorized: Bool, albums: [Album]) -> Self {
    return .init(
      authorize: Just(authorized).eraseToAnyPublisher(),
      fetch: { albums }
    )
  }
}

public extension PhotoLibrary.Album {
  static func stub(size: Int) -> Self {
    return .init(
      id: UUID(),
      name: "album",
      size: size,
      thumbnail: { _ in
        Future.deferred { photoPromise in
          photoPromise(.success(UIImage(color: .blue)!))
        }
      },
      images: {
        Array(repeating: { PhotoLibrary.Image.stub() }, count: size).map { $0() }
      }
    )
  }
}

public extension PhotoLibrary.Image {
  static func stub() -> Self {
    .init(
      id: UUID(),
      date: Date(),
      index: 0,
      photoWithSize: { size in
        Future.deferred { photoPromise in
          photoPromise(.success(UIImage(color: .blue)!))
        }
      }
    )
  }
}
#endif

extension UIImage.Orientation {
  init(_ cgOrientation: CGImagePropertyOrientation) {
    switch cgOrientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    }
  }
}

public extension UIImage {
  func normalizeOrientation() -> UIImage {
    UIGraphicsBeginImageContext(size)
    draw(at: .zero)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage ?? self
  }
}
