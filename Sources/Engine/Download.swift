import DazeFoundation
import Photos
import Combine

public protocol AssetChangeRequestBacked {
  func assetChangeRequest() -> PHAssetChangeRequest?
}

extension MediaDownloader where Media: AssetChangeRequestBacked {
  public static func photos() -> Self {
    func download(_ media: Media) -> AnyPublisher<Void, Error> {
      return Future.deferred { (promise: @escaping (Result<Void, Error>) -> Void) in
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized: promise(.success(()))
        case .notDetermined:
          PHPhotoLibrary.requestAuthorization { (status) in
            guard status == .authorized else { return }
            promise(.success(()))
          }
        default: return
        }
      }
      .flatMap { performDownload(media) }
      .eraseToAnyPublisher()
    }
    
    func performDownload(_ media: Media) -> AnyPublisher<Void, Error> {
      createAlbum(name: "daze cam")
        .flatMap { album in
          PHPhotoLibrary.shared().performChanges {
            guard let album = album else {
              _ = media.assetChangeRequest()
              return
            }
            let changeRequest: PHAssetChangeRequest? = media.assetChangeRequest()
            guard
              let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
              let photoPlaceholder = changeRequest?.placeholderForCreatedAsset
            else { return }
            albumChangeRequest.addAssets([photoPlaceholder] as NSArray)
          }
        }
        .eraseToAnyPublisher()
    }
    
    func createAlbum(name: String) -> AnyPublisher<PHAssetCollection?, Error> {
      if let album = albumFor(title: name) { return Just(album).setFailureType(to: Error.self).eraseToAnyPublisher() }
      return PHPhotoLibrary.shared()
        .performChanges {
          return PHAssetCollectionChangeRequest
            .creationRequestForAssetCollection(withTitle: name)
            .placeholderForCreatedAssetCollection
        }
        .map { placeholder in
          PHAssetCollection
            .fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
            .firstObject
        }
        .eraseToAnyPublisher()
    }
    
    func albumFor(title: String) -> PHAssetCollection? {
      let fetchOptions = PHFetchOptions()
      fetchOptions.predicate = NSPredicate(format: "title = %@", title)
      let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
      return collections.firstObject
    }
    
    return .init(download: download)
  }
}

public struct MediaDownloader<Media> {
  public let download: (_ media: Media) -> AnyPublisher<Void, Error>
}

extension PHPhotoLibrary {
  func performChanges<T>(_ block: @escaping () -> T) -> AnyPublisher<T, Error> {
    var value: T?
    return Future.deferred { (promise: @escaping (Result<T, Error>) -> Void) in
      self.performChanges(
        { () -> Void in
          value = block()
        },
        completionHandler: { completed, error in
          if !completed, let error = error { return promise(.failure(error)) }
          if let value = value { promise(.success(value)) }
      })
    }
  }
}

#if DEBUG
public extension MediaDownloader {
  static func mock(success: Bool) -> MediaDownloader<Media> {
    .init { _ in
      success ? .success(()) : .fail(GenericError("fuck"))
    }
  }
}
#endif
