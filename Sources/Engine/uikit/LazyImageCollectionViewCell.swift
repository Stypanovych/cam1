import UIKit
import Combine
import SnapKit
import ImageProcessor

extension LazyImageCollectionViewCell {
  public enum SelectionState {
    case selectable(selected: Bool)
    case unselectable
  }
}

open class LazyImageCollectionViewCell: UICollectionViewCell {
  private var cancellable: AnyCancellable?
  //private static let queue = DispatchQueue(label: "LazyImageCollectionViewCell", qos: .userInteractive, attributes: .concurrent)
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }
  
  public func configure(
    with image: AnyPublisher<UIImage, GenericError>,
    //zoomable: Bool = false,
    selectionState: SelectionState // TODO: abstraction
    //layout: Layout
  ) {
    cancellable = image
      .subscribe(on: uiBackgroundQueue)
      .replaceError(with: UIImage())
      .receive(on: DispatchQueue.main)
      .sink { [weak self] image in
        guard let self = self else { return }
        self.imageView.image = image
      }
    switch selectionState {
    case .selectable(selected: true):
      contentView.layer.borderWidth = Theme.shared.unit
      contentView.layer.borderColor = Theme.shared.red.withAlphaComponent(1).cgColor
    case .selectable(selected: false):
      contentView.layer.borderWidth = Theme.shared.unit / 4
      contentView.layer.borderColor = Theme.shared.red.withAlphaComponent(1).cgColor
    case .unselectable:
      contentView.layer.borderWidth = 0
    }
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupViews() {
    contentView.layer.borderColor = Theme.shared.color.red.cgColor
    contentView.addSubview(imageView)
    
    imageView.snp.remakeConstraints { make in
      make.width.height.equalToSuperview()
      make.center.equalToSuperview()
    }
  }
  
  open override func prepareForReuse() {
    super.prepareForReuse()
    cancellable = nil
    imageView.image = nil // this causes image to go blank before reloading
  }
  
  //public private(set) lazy var containerView = ZoomView(imageView)
  
  public private(set) lazy var imageView = UIImageView() ~~ {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
  }
  
//  public struct Layout {
//    public let makeConstraints: (UIImageView) -> Void
//    
//    public static let fill: Self = .init {
//      $0.snp.remakeConstraints { make in
//        make.width.height.equalToSuperview()
//        make.center.equalToSuperview()
//      }
//    }
//    
//    public static let fit: Self = .init { imageView in
//      imageView.snp.remakeConstraints { make in
//        make.width.equalToSuperview().priority(.high)
//        make.height.equalToSuperview().priority(.high)
//        make.height.lessThanOrEqualToSuperview()
//        make.width.lessThanOrEqualToSuperview()
//        make.center.equalToSuperview()
//        guard let size = imageView.image?.size else { return }
//        make.width.equalTo(imageView.snp.height).multipliedBy(CGFloat(size.width) / CGFloat(size.height))
//      }
//    }
//  }
}
