import UIKit
import Engine
import ComposableArchitecture
import Combine
import SwiftUI

open class AlbumCollectionViewCell: UICollectionViewCell {
  private var cancellable: AnyCancellable?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }
  
  public func configure(with album: PhotoLibrary.Album) {
    cancellable = album.thumbnail(.custom(frame.size))
      .subscribe(on: uiBackgroundQueue)
      .replaceError(with: UIImage())
      .receive(on: DispatchQueue.main)
      .sink { [weak self] image in
        guard let self = self else { return }
        self.imageView.image = image
      }
    titleLabel.text = album.name
    countLabel.text = "\(album.size)"
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupViews() {
    contentView.addSubview(imageView)
    imageView.addSubview(titleBackground)
    titleBackground.addSubview(titleLabel)
    titleBackground.addSubview(countLabel)
    
    imageView.snp.remakeConstraints { make in
      make.width.height.equalToSuperview()
      make.center.equalToSuperview()
    }
    
    titleBackground.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    titleLabel.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
    
    countLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(Theme.shared.unit / 2)
      make.centerX.equalToSuperview()
    }
  }
  
  open override func prepareForReuse() {
    super.prepareForReuse()
    cancellable = nil
    imageView.image = nil
  }
  
  private lazy var titleBackground = UIView() ~~ {
    $0.backgroundColor = .black.withAlphaComponent(0.75)
  }
  
  private lazy var titleLabel = UILabel() ~~ {
    $0.textColor = .dazecam.light
    $0.font = .dazecam.main.large.black.uiFont
  }
  
  private lazy var countLabel = UILabel() ~~ {
    $0.textColor = .dazecam.light.withAlphaComponent(0.5)
    $0.font = .dazecam.main.small.heavy.uiFont
  }

  public private(set) lazy var imageView = UIImageView() ~~ {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
  }
}

public final class AlbumCollection: UIView {
  public typealias State = [PhotoLibrary.Album]
  public typealias Action = PhotoLibrary.Album.ID
  
  private let store: Store<State, Action>
  private let viewStore: ViewStore<State, Action>
  
  private var cancellables: Set<AnyCancellable> = []
  
  public init(store: Store<State, Action>) {
    self.store = store
    self.viewStore = ViewStore(store)
    super.init(frame: .zero)
    setupViews()
    subscribeToViewStore()
  }
  
  private func subscribeToViewStore() {
    viewStore.publisher
      .sink { [unowned self] elements in
        let payloads: [CollectionView.Element<AlbumCollectionViewCell>] = elements.map { album in
          return .init(
            id: album.id,
            configure: { cell in cell.configure(with: album) },
            didSelect: { [unowned self] in self.viewStore.send(album.id) }
          )
        }
        self.collectionView.update(with: payloads)
      }
      .store(in: &cancellables)
  }
  
  private func setupViews() {
    addSubview(collectionView)
    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private lazy var collectionViewLayout: UICollectionViewLayout = {
    let itemsPerRow: CGFloat = 3
    let margins: CGFloat = Theme.shared.unit / 2
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1 / itemsPerRow),
      heightDimension: .fractionalWidth(1 / itemsPerRow)
    )
    let fullPhotoItem = NSCollectionLayoutItem(layoutSize: itemSize) ~~ {
      $0.contentInsets = .init(top: margins, leading: margins, bottom: margins, trailing: margins)
    }
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .fractionalWidth(1 / itemsPerRow)
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitem: fullPhotoItem,
      count: 3
    ) ~~ {
      $0.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    //group.interItemSpacing = .fixed(margins)
    let section = NSCollectionLayoutSection(group: group) ~~ {
      $0.contentInsets = .init(top: margins / 2, leading: margins, bottom: margins / 2, trailing: margins)
    }
    let layout = UICollectionViewCompositionalLayout(section: section)
    return layout
  }()
  
  public private(set) lazy var collectionView = CollectionView(collectionViewLayout: collectionViewLayout)
}
