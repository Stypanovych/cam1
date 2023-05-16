import AVKit

public final class Video {
  public let file: File.Pointer
  private(set) lazy var asset: AVAsset = { AVAsset(url: file.url) }()
  private lazy var generator: AVAssetImageGenerator = {
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceAfter = .zero
    generator.requestedTimeToleranceBefore = .zero
    return generator
  }()
  
  public private(set) lazy var frameCount: Int = {
    return Int(Float(duration) * frameRate)
  }()
  
  public private(set) lazy var frameRate: Float = {
    return asset.tracks(withMediaType: .video).first!.nominalFrameRate
  }()
  
  public private(set) lazy var duration: Double = {
    return CMTimeGetSeconds(asset.duration)
  }()
  
  public private(set) lazy var size: CGSize = {
    let assetTrack = asset.tracks(withMediaType: .video).first!
    let size = assetTrack.naturalSize.applying(assetTrack.preferredTransform)
    return CGSize(width: abs(size.width), height: abs(size.height))
  }()
  
  public init(file: File.Pointer) {
    self.file = file
  }
  
  public subscript(_ frame: Int) -> CGImage? {
    return try? generator.copyCGImage(
      at: CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(frameRate)),
      actualTime: nil
    )
  }
  
  public subscript(_ normal: CGFloat) -> CIImage? {
    return (try? generator.copyCGImage(
      at: CMTime(value: CMTimeValue(Int(normal * CGFloat(frameCount))), timescale: CMTimeScale(frameRate)),
      actualTime: nil
    )).map(CIImage.init)
  }
}

extension Video: Hashable {
  public static func == (lhs: Video, rhs: Video) -> Bool {
    return lhs.file == rhs.file
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(file)
  }
}

public final class FrameGrabber {
  private var frame: (index: Int, image: CIImage?) = (index: -1, image: nil)
  private let video: Video
  
  public init(video: Video) {
    self.video = video
  }
  
  public func grab(_ normal: CGFloat) -> CIImage? {
    let index = Int(normal * CGFloat(video.frameCount - 1))
    return grab(index)
  }
  
  public func grab(_ frameIndex: Int) -> CIImage? {
    if frameIndex == frame.index { return frame.image }
    frame = (
      index: frameIndex,
      image: video[frameIndex].map(CIImage.init)
    )
    return frame.image
  }
}

extension FrameGrabber: Equatable {
  public static func == (lhs: FrameGrabber, rhs: FrameGrabber) -> Bool {
    lhs.video == rhs.video
  }
}
