import UIKit
import SwiftUI

public class SegmentedCollectionView: CollectionView {
  private var lastOffset: CGFloat? = nil
  private var offset: CGFloat {
    get { layout.horizontal ? contentOffset.x : contentOffset.y }
    set { layout.horizontal ? (contentOffset.x = newValue) : (contentOffset.y = newValue) }
  }
  private var itemSpace: CGFloat { layout.size + layout.minimumLineSpacing }
  private var itemCount: Int { customDataSource.snapshot().numberOfItems }
  private let layout: SegmentedCollectionViewLayout
//  private var page: Int {
//    let page = Int(round(offset / (itemSpace)))
//    return min(page, max(0, page))
//  }

  public init(direction: UICollectionView.ScrollDirection, size: CGFloat, spacing: CGFloat = 0) {
    self.layout = SegmentedCollectionViewLayout(direction: direction, size: size, spacing: spacing)
    super.init(collectionViewLayout: layout)
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var lastSelectedIndex: Int? = nil

  public override func scrollDidMove() {
    let currentOffset = offset
    self.lastOffset = lastOffset ?? currentOffset // TODO: reset last offset?
    guard
      let lastOffset = lastOffset,
      lastOffset != currentOffset
    else { return }
    defer { self.lastOffset = currentOffset }
    let smaller = min(currentOffset, lastOffset)
    let bigger = max(currentOffset, lastOffset)
    let straddledIndex: Int? = {
      for (index, offset) in layout.itemOffsets(self).enumerated() {
        if (smaller <= offset) && (bigger >= offset) && (lastOffset != offset) { return index }
      }
      return nil
    }()
    if let straddledIndex = straddledIndex {
      select(index: straddledIndex)
    }
    super.scrollDidMove()
  }
  
  // if it's where
  private func select(index: Int) {
    guard
      !isAnimatingPublisher.value, // TODO: this can be true but never set to false sometimes
      index != lastSelectedIndex
    else { return }
    lastSelectedIndex = index // an index cannot be selected twice in a row
    UISelectionFeedbackGenerator().selectionChanged()
    customDataSource.itemIdentifier(for: .init(row: index, section: 0))?.didSelect()
  }
  
  public func scroll(to page: Int, animated: Bool) {
    //guard page != self.page else { return }
    guard currentIndex != page else { return }
    //lastSelectedIndex = page
    scrollToItem(
      at: IndexPath(item: page, section: 0),
      at: layout.horizontal ? .centeredHorizontally : .centeredVertically,
      animated: animated
    )
  }
  
  private var currentIndex: Int? {
    layout.itemOffsets(self)
      .enumerated()
      .min { abs($0.1 - offset) < abs($1.1 - offset) }?
      .0
  }
  
  // the proposedOffset is different from scrollDidSettle
  public override func scrollDidSettle() {
    super.scrollDidSettle()
    self.lastOffset = offset
    currentIndex.map { select(index: $0) }
//    let closestIndex = layout.itemOffsets(self).enumerated().min { abs($0.1 - offset) < abs($1.1 - offset) }
//    if let closestIndex = closestIndex { select(index: closestIndex.0) }
  }
  
  /*
   - touch index -> select
   - scroll through index -> select
   - settle on index -> select
   
   */
  
  // if not already at index then select
  public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //scroll(to: indexPath.row, animated: true)
    select(index: indexPath.row)
  }
}

public class SegmentedCollectionViewLayout: UICollectionViewFlowLayout {
  let size: CGFloat
  let itemInsets: CGFloat = 10.0
  let direction: UICollectionView.ScrollDirection
  
  var horizontal: Bool { direction == .horizontal }
  
  public init(direction: UICollectionView.ScrollDirection, size: CGFloat, spacing: CGFloat = 0) {
    self.size = size
    self.direction = direction
    super.init()
    scrollDirection = direction
    minimumInteritemSpacing = 0
    minimumLineSpacing = spacing
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func prepare() {
    super.prepare()
    guard let collectionView = collectionView else { return }
    
    switch direction {
    case .horizontal:
      let inset = collectionView.bounds.width / 2 - size / 2
      itemSize = CGSize(width: size, height: collectionView.bounds.height)
      sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    case .vertical:
      let inset = collectionView.bounds.height / 2 - size / 2
      itemSize = CGSize(width: collectionView.bounds.width, height: size)
      sectionInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
    default: break
    }
  }
  
  override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }
  
  public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard
      let attributes = super.layoutAttributesForElements(in: rect),
      let collectionView = self.collectionView
    else { return nil }
    return attributes.map {
      let totalSize = size + itemInsets
      let distanceFromCenter = horizontal ? ($0.frame.midX - collectionView.bounds.midX) : ($0.frame.midY - collectionView.bounds.midY)
      $0.alpha = 1.3 - min(abs(distanceFromCenter) / totalSize, 1)
      //$0.alpha = 1 / max(abs($0.frame.midX - collectionView.bounds.midX) / width, 1)
      return $0
    }
  }
  
  func itemOffsets(_ collectionView: UICollectionView) -> [CGFloat] {
    (0...collectionView.numberOfItems(inSection: 0)).compactMap {
      let origin = collectionView.layoutAttributesForItem(at: .init(item: $0, section: 0))?.frame.origin
      return horizontal
        ? origin.map { $0.x - sectionInset.left }
        : origin.map { $0.y - sectionInset.top }
    }
  }
  
  public override func targetContentOffset(
    forProposedContentOffset proposedContentOffset: CGPoint,
    withScrollingVelocity velocity: CGPoint
  ) -> CGPoint {
    guard let collectionView = collectionView else { return proposedContentOffset }
//    let proposedContentOffset = super.targetContentOffset(
//      forProposedContentOffset: proposedContentOffset,
//      withScrollingVelocity: .init(x: velocity.x / 100, y: velocity.y / 100)
//    )
    let itemOffsets = itemOffsets(collectionView)
    let offset = horizontal ? collectionView.contentOffset.x : collectionView.contentOffset.y
    let proposedOffset = horizontal ? proposedContentOffset.x : proposedContentOffset.y
    let newOffset: CGFloat = {
      let velocity = horizontal ? velocity.x : velocity.y
      if abs(velocity) > 0 {
        if velocity > 0 {
          return itemOffsets
            .filter { ($0 - offset) > 0 }
            .min()
            ?? itemOffsets.last
            ?? proposedOffset
        } else {
          return itemOffsets
            .filter { ($0 - offset) < 0 }
            .max()
            ?? itemOffsets.first
            ?? proposedOffset
        }
      } else {
        return itemOffsets.min { abs($0 - offset) < abs($1 - offset) } ?? proposedOffset
      }
    }()
    //let newOffset = itemOffsets.min { abs($0 - proposedOffset) < abs($1 - proposedOffset) } ?? proposedOffset
    return horizontal
      ? CGPoint(x: newOffset, y: proposedContentOffset.y)
      : CGPoint(x: proposedContentOffset.x, y: newOffset)
  }
}
