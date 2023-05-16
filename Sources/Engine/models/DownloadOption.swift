import Photos

public enum ImageOption: Hashable {
  case download(Download)
  case delete
  
  public struct Download: Hashable {
    public let text: String
    public let keyPaths: [KeyPath<FilteredImage, LocalImage>]
    
    public static let filtered: Self = .init(text: "filtered", keyPaths: [\.filteredImagePath.localImage])
    public static let original: Self = .init(text: "original", keyPaths: [\.originalImagePath.localImage])
    public static let both: Self = .init(text: "both", keyPaths: [\.originalImagePath.localImage, \.filteredImagePath.localImage])
    
    public static let all: [Self] = [.original, .filtered, .both]
  }
}

public struct LocalImage {
  public let file: File.Pointer
  
  public init(file: File.Pointer) {
    self.file = file
  }
}

extension LocalImage: AssetChangeRequestBacked {
  public func assetChangeRequest() -> PHAssetChangeRequest? {
    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: file.url)
  }
}

extension File.Pointer {
  var localImage: LocalImage { .init(file: self) }
}
