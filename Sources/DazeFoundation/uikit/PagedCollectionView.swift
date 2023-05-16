import UIKit
import Combine

public class PagedCollectionView: CollectionView {
 private static func collectionViewLayout(direction: UICollectionView.ScrollDirection) -> UICollectionViewLayout {
   let itemSize = NSCollectionLayoutSize(
     widthDimension: .fractionalWidth(1),
     heightDimension: .fractionalHeight(1)
   )
   let fullPhotoItem = NSCollectionLayoutItem(layoutSize: itemSize)
   let groupSize = NSCollectionLayoutSize(
     widthDimension: .fractionalWidth(1),
     heightDimension: .fractionalHeight(1)
   )
   let group = NSCollectionLayoutGroup.vertical(
     layoutSize: groupSize,
     subitem: fullPhotoItem,
     count: 1
   )
   let section = NSCollectionLayoutSection(group: group)
   let config = UICollectionViewCompositionalLayoutConfiguration() ~~ {
     $0.scrollDirection = direction
   }
   let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
   return layout
 }
 
 private let scrollDirection: UICollectionView.ScrollDirection
 
 public init(scrollDirection: UICollectionView.ScrollDirection) {
   self.scrollDirection = scrollDirection
   super.init(collectionViewLayout: PagedCollectionView.collectionViewLayout(direction: scrollDirection))
   isPagingEnabled = true
 }
 
 required init?(coder: NSCoder) {
   fatalError("init(coder:) has not been implemented")
 }
 
  // calls didBecomeVisible on first element before populated
  // update -> scroll ->
 public func update<Cell>(with elements: [Element<Cell>]) {
   //let previousCount = customDataSource.snapshot().numberOfItems
   //let newElementCount = previousCount > elements.count // if there was a deletion
   super.update(with: elements, animated: false)
   //if newElementCount { scrollDidSettle() }
 }
 
 override public func scrollDidSettle() {
   super.scrollDidSettle()
   let page: Int = {
     switch scrollDirection {
     case .horizontal: return Int(contentOffset.x / bounds.width)
     case .vertical: return Int(contentOffset.y / bounds.height)
     @unknown default: fatalError()
     }
   }()
   item(at: .init(row: page, section: 0))?.didBecomeVisible()
 }
}
