import Engine
import Metal
import CoreImage
import Combine
import ComposableArchitecture
import UIKit
import SnapKit

class EditImageCollectionViewCell: UICollectionViewCell {
  //private(set) var preview: PreviewView?
  private var cancellable: AnyCancellable?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  struct Preview {
    var view: PreviewView
    var longPress: UILongPressGestureRecognizer
  }
  
  private var preview: Preview?
  // same preview, different preview, no preview
  func configure(
    with image: AnyPublisher<UIImage, GenericError>,
    preview: Preview?
  ) {
    if let newPreview = preview {
      if let oldPreview = self.preview, newPreview.view != oldPreview.view {
        removePreview()
      }
      add(preview: newPreview)
    }
    else if preview == nil {
      removePreview()
    }
    self.preview = preview
    
    cancellable = image
      .subscribe(on: uiBackgroundQueue)
      .replaceError(with: UIImage())
      .receive(on: DispatchQueue.main)
      .share() // needed or else image published from before reuse also published
      .sink { [weak self] image in
        guard let self = self else { return }
        self.imageView.image = image
        self.imageView.snp.remakeConstraints { make in
          make.width.equalToSuperview().priority(.high)
          make.height.equalToSuperview().priority(.high)
          make.height.lessThanOrEqualToSuperview()
          make.width.lessThanOrEqualToSuperview()
          make.center.equalToSuperview()
          guard let size = self.imageView.image?.size, size != .zero else { return }
          make.width.equalTo(self.imageView.snp.height).multipliedBy(CGFloat(size.width) / CGFloat(size.height))
        }
      }
  }
  
  func add(preview: Preview) {
//    guard preview == nil else { return preview! }
//    preview = PreviewView(
//      device: MTLCreateSystemDefaultDevice()!,
//      context: context,
//      renderScheduler: renderScheduler,
//      mainScheduler: mainScheduler
//    )
    imageView.addSubview(preview.view)
    imageView.isUserInteractionEnabled = true
    preview.view.snp.makeConstraints { make in
      make.edges.equalTo(imageView)
    }
    contentView.layoutIfNeeded()
    self.preview = preview
    //return preview!
  }
  
  func removePreview() {
    preview?.view.removeFromSuperview()
    (preview?.longPress).map { contentView.removeGestureRecognizer($0) }
    preview = nil
  }
  
  //private var longPress: UIGestureRecognizer?
  
//  func addLongPress() -> AnyPublisher<GestureType, Never> {
//    let longPress = UILongPressGestureRecognizer() ~~ {
//      $0.minimumPressDuration = 0.05
//      $0.numberOfTapsRequired = 0
//    }
//    self.longPress = longPress
//    return contentView
//      .gesture(.longPress(longPress))
//      .eraseToAnyPublisher()
//  }
  
//  func removeLongPress() {
//    longPress.map { contentView.removeGestureRecognizer($0) }
//  }
  
//  func add(frame: CIImage) {
//    preview?.add(frame: frame)
//  }
  
//  func removePreview(replacementImage: UIImage?) {
//    guard let preview = preview else { return }
//    preview.removeFromSuperview()
//    self.preview = nil
//    imageView.image = replacementImage
//  }
  
  // prepare for reuse -> same
  // prepare for reuse -> different cell
  override func prepareForReuse() {
    super.prepareForReuse()
    //guard preview == nil else { return }
    cancellable?.cancel()
    cancellable = nil
    imageView.image = nil
    //removePreview()
    // every time layoutSubviews -> prepareForReuse
    // no matter what configure will always be called
    //removePreview(replacementImage: nil)
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupViews() {
    containerView.addSubview(imageView)
    contentView.addSubview(containerView)
    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    containerView.pinchGestureRecognizer.map { contentView.addGestureRecognizer($0) }
    contentView.addGestureRecognizer(containerView.panGestureRecognizer)

//    imageView.snp.makeConstraints { make in
//      make.width.height.equalToSuperview() // necessary to not expand zoomview
//      make.center.equalToSuperview()
//    }
    
//    imageView.snp.makeConstraints { make in
//      make.width.equalToSuperview().priority(.high)
//      make.height.equalToSuperview().priority(.high)
//      make.height.lessThanOrEqualToSuperview()
//      make.width.lessThanOrEqualToSuperview()
//      make.center.equalToSuperview()
//      guard let size = self.imageView.image?.size else { return }
//      make.width.equalTo(self.imageView.snp.height).multipliedBy(CGFloat(size.width) / CGFloat(size.height))
//    }
  }
  
 //private var aspectConstraint: ConstraintMakerEditable?
  
  public private(set) lazy var containerView = ZoomView(imageView) ~~ {
    $0.maximumZoomScale = 6
    $0.isScrollEnabled = true
    $0.isUserInteractionEnabled = false
  }
  
  public private(set) lazy var imageView = UIImageView() ~~ {
    $0.contentMode = .scaleAspectFit
    $0.clipsToBounds = true
  }
}
