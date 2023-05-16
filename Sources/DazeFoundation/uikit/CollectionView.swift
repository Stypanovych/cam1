 import UIKit
 import Combine

public class CollectionView: UICollectionView {
   //public let didSelectPublisher = PassthroughSubject<Int, Never>()
   //public let visibleIndecesPublisher = PassthroughSubject<[Int], Never>()
   public let isScrollingPublisher = CurrentValueSubject<Bool, Never>(false)
   public let isAnimatingPublisher = CurrentValueSubject<Bool, Never>(false)
   public let scrollOffsetPublisher = PassthroughSubject<CGPoint, Never>()

   public init(collectionViewLayout layout: UICollectionViewLayout) {
     super.init(frame: .zero, collectionViewLayout: layout)
     dataSource = customDataSource
     delegate = self
   }
   
   required init?(coder: NSCoder) {
     fatalError("init(coder:) has not been implemented")
   }
   
   //@available(iOS 14.0, *)
//   private let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { cell, indexPath, item in
//     item.update(cell)
//   }
   
   private(set) lazy var customDataSource = UICollectionViewDiffableDataSource<Int, Item>(collectionView: self) { collectionView, indexPath, item in
//     if #available(iOS 14.0, *) {
//       return collectionView.dequeueConfiguredReusableCell(using: self.cellRegistration, for: indexPath, item: item)
//     } else {
       let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.reuseId, for: indexPath)
       item.update(cell)
       return cell
//     }
   }
   
   public func item(at indexPath: IndexPath) -> Item? {
     customDataSource.itemIdentifier(for: indexPath)
   }

   public func indexPath(for id: AnyHashable) -> IndexPath? {
     return customDataSource
       .indexPath(for: Item(id: id, reuseId: "", update: { _ in }, didSelect: { }, didBecomeVisible: { }))
   }
   
//   public func update<Cell>(id: AnyHashable, element: Element<Cell>) -> UICollectionViewCell? {
//     guard
//      let indexPath = indexPath(for: id),
//      let item = item(at: indexPath) else { return nil }
//     let newItem = Item(
//      id: element.id,
//      reuseId: String(describing: Cell.self),
//      update: element.configure,
//      didSelect: element.didSelect,
//      didBecomeVisible: element.didBecomeVisible
//    )
//     precondition(item.reuseId == newItem.reuseId)
//     var snapshot = customDataSource.snapshot()
//     snapshot.insertItems([newItem], afterItem: item)
//     snapshot.deleteItems([item])
//     customDataSource.apply(snapshot, animatingDifferences: true)
//   }
  
  public func reconfigure(cells: [UICollectionViewCell]) {
    cells
      .compactMap { cell in
        indexPath(for: cell)
          .map { customDataSource.itemIdentifier(for: $0) }?
          .map { (cell, $0) }
      }
      .forEach { cell, item in
        item.update(cell)
      }
  }
  
  public func reconfigure(items: [Item]) {
    items
      .compactMap { item in
        indexPath(for: item.id)
          .map { indexPath in cellForItem(at: indexPath) }?
          .map { ($0, item) }
      }
      .forEach { cell, item in
        item.update(cell)
      }
  }
  
  public func reconfigureAllItems() {
    reconfigure(items: customDataSource.snapshot().itemIdentifiers)
  }

   public func update<Cell>(with elements: [Element<Cell>], animated: Bool = true) {
     let factory = ItemFactory(elements: elements)
     register(factory.cellClass, forCellWithReuseIdentifier: factory.reuseId)
     
     var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()
     snapshot.appendSections([1])
     snapshot.appendItems(factory.items)
     
     //customDataSource.up
    // if cell id changes then it is recreated. If cell id is same but content needs to change then you have to reconfigure it
     customDataSource.apply(snapshot, animatingDifferences: animated)
//     customDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
//       if animated { self?.scrollDidSettle() } // TODO: unhack
//     }
   }
 }

extension CollectionView: UICollectionViewDelegate {
  public override func scrollToItem(
    at indexPath: IndexPath,
    at scrollPosition: UICollectionView.ScrollPosition,
    animated: Bool
  ) {
    isAnimatingPublisher.send(animated)
    super.scrollToItem(
      at: indexPath,
      at: scrollPosition,
      animated: animated
    )
  }
  
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //didSelectPublisher.send(indexPath.row)
    item(at: indexPath)?.didSelect()
  }
  
  //public func collectionView
  
  // MARK: - UIScrollViewDelegate
  
  @objc
  public func scrollDidBegin() {
    isScrollingPublisher.send(true)
  }
  
  @objc
  public func scrollDidMove() {
    scrollOffsetPublisher.send(contentOffset)
  }
  
  @objc
  public func scrollDidSettle() {
    isScrollingPublisher.send(false)
  }
  
  public final func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { scrollDidBegin() }
  public final func scrollViewDidScroll(_ scrollView: UIScrollView) { scrollDidMove() }
  public final func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { scrollDidSettle() }
  public final func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    scrollDidSettle()
    isAnimatingPublisher.send(false)
  }
  public final func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    guard !decelerate else { return }
    scrollDidSettle()
  }
}

// create cell factory
extension CollectionView {
  public struct Element<Cell: UICollectionViewCell> {
    let id: AnyHashable
    let configure: (Cell) -> Void
    let didSelect: () -> Void
    let didBecomeVisible: () -> Void
    
    public init(
      id: AnyHashable,
      configure: @escaping (Cell) -> Void,
      didSelect: @escaping () -> Void,
      didBecomeVisible: @escaping () -> Void = {}
    ) {
      self.id = id
      self.configure = configure
      self.didSelect = didSelect
      self.didBecomeVisible = didBecomeVisible
    }
  }
  
  struct ItemFactory {
    let cellClass: UICollectionViewCell.Type
    let reuseId: String
    let items: [Item]
    
    init<Cell: UICollectionViewCell>(elements: [Element<Cell>]) {
      let reuseId = String(describing: Cell.self)
      self.cellClass = Cell.self
      self.reuseId = reuseId
      self.items = elements.map { payload in
        return Item(
          id: payload.id,
          reuseId: reuseId,
          update: payload.configure,
          didSelect: payload.didSelect,
          didBecomeVisible: payload.didBecomeVisible
        )
      }
    }
  }
  
  public struct Item: Hashable {
    let id: AnyHashable
    let reuseId: String
    let update: (UICollectionViewCell) -> ()
    public let didSelect: () -> Void
    public let didBecomeVisible: () -> Void
    
    init<Cell: UICollectionViewCell>(
      id: AnyHashable,
      reuseId: String,
      update: @escaping (Cell) -> (),
      didSelect: @escaping () -> Void,
      didBecomeVisible: @escaping () -> Void
    ) {
      self.id = id
      self.reuseId = reuseId
      self.update = { update($0 as! Cell) }
      self.didSelect = didSelect
      self.didBecomeVisible = didBecomeVisible
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
    
    public static func == (lhs: CollectionView.Item, rhs: CollectionView.Item) -> Bool {
      lhs.id == rhs.id
    }
  }
}
