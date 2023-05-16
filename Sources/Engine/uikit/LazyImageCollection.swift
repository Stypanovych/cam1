import SwiftUI
import ComposableArchitecture
import Combine
import ImageProcessor

public extension FilteredImage {
  func lazyImage(for keyPath: KeyPath<Self, String>, sizeToFit: CGSize? = nil) -> LazyImage<FilteredImage> {
    return .init(
      value: self,
      future: Deferred {
        Future { promise in
          let image = UIImage(contentsOfFile: self[keyPath: keyPath]) ?? UIImage() // TODO: figure out why this was crashing
          let scaledImage = sizeToFit
            .map { image.scaleToFit($0) }
            ?? image
          promise(.success(scaledImage))
        }
      }.eraseToAnyPublisher()
    )
  }
}

struct Selectable<T: Hashable>: Hashable {
  var selectable: Bool
  var value: T
}

// id of model must stay same when updating, but the id of the collectionview item must change
public final class LazyImageCollection<Element: Identifiable & Hashable>: UIView {
  public struct State: Equatable {
    public var canSelect: Bool
    public var elements: [Selection<LazyImage<Element>>]
    public var selectionCount: Int
    
    public init(
      canSelect: Bool,
      elements: [Selection<LazyImage<Element>>],
      selectionCount: Int
    ) {
      self.canSelect = canSelect
      self.elements = elements
      self.selectionCount = selectionCount
    }
    
    public static var disabled: Self {
      .init(canSelect: false, elements: [], selectionCount: 0)
    }
  }
  
  public typealias Action = Element.ID
  
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
    //viewStore.send(.onAppear)
    
    viewStore.publisher.canSelect
      .sink { [unowned self] canSelect in
        canSelect
          ? self.slideGesture.add(to: self.collectionView)
          : self.slideGesture.remove()
      }
      .store(in: &cancellables)
    
    viewStore.publisher.selectionCount
      .dropFirst()
      .sink { _ in
        UISelectionFeedbackGenerator().selectionChanged()
      }
      .store(in: &cancellables)
    
    viewStore.publisher.elements
      .combineLatest(viewStore.publisher.canSelect)
      .sink { [unowned self] elements, canSelect in
        let payloads: [CollectionView.Element<LazyImageCollectionViewCell>] = elements.reversed().map { selectionLazyImage in
          return .init(
            id: selectionLazyImage.element.value.id, // only create new cell if id changes
            configure: { cell in
              let image = selectionLazyImage.element
              cell.configure(
                with: image.future,
                selectionState: canSelect ? .selectable(selected: selectionLazyImage.isSelected) : .unselectable
              )
            },
            didSelect: { [unowned self] in self.viewStore.send(selectionLazyImage.element.value.id) }
          )
        }
        self.collectionView.update(with: payloads)
        // reconfigure cells to reflect changes to selection state
        // could do this only when selection changes for more efficiency
        self.collectionView.reconfigureAllItems()
      }
      .store(in: &cancellables)
  }
  
  private func setupViews() {
    addSubview(collectionView)
    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    Publishers.Merge(
      slideGesture.movedPublisher.map { $0 as CGPoint? },
      slideGesture.endedPublisher.flatMap { point -> AnyPublisher<CGPoint?, Never> in
        [point, nil].publisher.eraseToAnyPublisher()
      }
    )
      .map { [unowned self] point -> IndexPath? in
        guard
          let point = point,
          let indexPath = self.collectionView.indexPathForItem(at: point)
        else { return nil }
        return indexPath
      }
      .removeDuplicates()
      .sink { [unowned self] indexPath in
        indexPath.map {
          self.collectionView.item(at: $0)?.didSelect()
        }
      }
      .store(in: &cancellables)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private lazy var collectionViewLayout: UICollectionViewLayout = {
    //let margins = Theme.shared.margins
    let margins: CGFloat = Theme.shared.unit / 2
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1 / 3),
      heightDimension: .fractionalWidth(1 / 3)
    )
    let fullPhotoItem = NSCollectionLayoutItem(layoutSize: itemSize) ~~ {
      $0.contentInsets = .init(top: margins, leading: margins, bottom: margins, trailing: margins)
    }
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .fractionalWidth(1 / 3)
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

  private lazy var slideGesture = MultiGesture.slide
  public private(set) lazy var collectionView = CollectionView(collectionViewLayout: collectionViewLayout)
}


//public final class SelectableLazyImageCollection<Element: Identifiable & Hashable>: UIView {
//  public struct State: Equatable {
//    public var canSelect: Bool
//    public var selectedElements: Set<LazyImage<Element>>
//    public var elements: [LazyImage<Element>]
//    public var selectionCount: Int
//
//    public init(
//      canSelect: Bool,
//      elements: [LazyImage<Element>],
//      selectionCount: Int
//    ) {
//      self.canSelect = canSelect
//      self.elements = elements
//      self.selectionCount = selectionCount
//    }
//  }
//
//  public typealias Action = Element.ID
//
//  private let store: Store<State, Action>
//  private let viewStore: ViewStore<State, Action>
//
//  private var cancellables: Set<AnyCancellable> = []
//
//  public init(store: Store<State, Action>) {
//    self.store = store
//    self.viewStore = ViewStore(store)
//    super.init(frame: .zero)
//    setupViews()
//    subscribeToViewStore()
//  }
//
//  private func subscribeToViewStore() {
//    //viewStore.send(.onAppear)
//
//    viewStore.publisher.canSelect
//      .sink { [unowned self] canSelect in
//        canSelect
//          ? self.slideGesture.add(to: self.collectionView)
//          : self.slideGesture.remove()
//      }
//      .store(in: &cancellables)
//
//    viewStore.publisher.selectionCount
//      .dropFirst()
//      .sink { _ in
//        UISelectionFeedbackGenerator().selectionChanged()
//      }
//      .store(in: &cancellables)
//
//    // needs to have selection data or else will be deselected
//    viewStore.publisher.elements
//      //.combineLatest(viewStore.publisher.canSelect)
//      .withLatestFrom(viewStore.publisher.selectedElements)
//      .sink { [unowned self] elements, selectedElements in
//        let payloads: [CollectionView.Element<LazyImageCollectionViewCell>] = elements.reversed()
//          .map { Selection(element: $0, isSelected: selectedElements.contains($0)) }
//          .map { selectionLazyImage in
//            return .init(
//              id: selectionLazyImage,
//              configure: { cell in
//                let image = selectionLazyImage.element
//                cell.configure(
//                  with: image.future,
//                  selectionState: canSelect ? .selectable(selected: selectionLazyImage.isSelected) : .unselectable
//                )
//              },
//              didSelect: { [unowned self] in self.viewStore.send(selectionLazyImage.element.value.id) }
//            )
//          }
//        self.collectionView.update(with: payloads)
//      }
//      .store(in: &cancellables)
//
//    viewStore.publisher.selectedElements
//      .prepend([])
//      .collect(2)
//      .sink { [unowned self] selectedElements in
//        let oldElements = selectedElements[0]
//        let newElements = selectedElements[1]
//        let elementsToSelect = newElements.subtracting(oldElements)
//        let elementsToDeselect = oldElements.subtracting(newElements)
//        elementsToSelect.forEach {
//          self.collectionView.update(id: Selection.selected(<#T##element: _##_#>), element: <#T##CollectionView.Element<Cell>#>)
//        }
//        
////        let indexPaths = selectedElements.compactMap {
////          self.collectionView.indexPath(for: $0)
////        }
//      }
//      .store(in: &cancellables)
//  }
//
//  func element(for lazyImage: Selection<LazyImage<Element>>) -> CollectionView.Element<LazyImageCollectionViewCell> {
//    return .init(
//      id: Selectable(selectable: canSelect, value: selectionLazyImage),
//      configure: { cell in
//        let image = selectionLazyImage.element
//        cell.configure(
//          with: image.future,
//          selectionState: canSelect ? .selectable(selected: selectionLazyImage.isSelected) : .unselectable
//        )
//      },
//      didSelect: { [unowned self] in self.viewStore.send(selectionLazyImage.element.value.id) }
//    )
//  }
//
//  private func setupViews() {
//    addSubview(collectionView)
//    collectionView.snp.makeConstraints { make in
//      make.edges.equalToSuperview()
//    }
//
//    Publishers.Merge(
//      slideGesture.movedPublisher.map { $0 as CGPoint? },
//      slideGesture.endedPublisher.flatMap { point -> AnyPublisher<CGPoint?, Never> in
//        [point, nil].publisher.eraseToAnyPublisher()
//      }
//    )
//      .map { [unowned self] point -> IndexPath? in
//        guard
//          let point = point,
//          let indexPath = self.collectionView.indexPathForItem(at: point)
//        else { return nil }
//        return indexPath
//      }
//      .removeDuplicates()
//      .sink { [unowned self] indexPath in
//        let item = indexPath.map { self.collectionView.item(at: $0) } else { return }
//        //indexPath.map { self.collectionView.item(at: $0)?.didSelect() }
//        item.didSelect()
//        //self.viewStore.elements[indexPath.row] // create new element
//        self.collectionView.update(id: item.id, element: <#T##CollectionView.Element<Cell>#>)
//        // call configure
//        // update snapshot
//        // then collectionview model is in sync with tca model
//      }
//      .store(in: &cancellables)
//  }
//
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//
//  private lazy var collectionViewLayout: UICollectionViewLayout = {
//    //let margins = Theme.shared.margins
//    let margins: CGFloat = Theme.shared.unit / 2
//    let itemSize = NSCollectionLayoutSize(
//      widthDimension: .fractionalWidth(1 / 3),
//      heightDimension: .fractionalWidth(1 / 3)
//    )
//    let fullPhotoItem = NSCollectionLayoutItem(layoutSize: itemSize) ~~ {
//      $0.contentInsets = .init(top: margins, leading: margins, bottom: margins, trailing: margins)
//    }
//    let groupSize = NSCollectionLayoutSize(
//      widthDimension: .fractionalWidth(1),
//      heightDimension: .fractionalWidth(1 / 3)
//    )
//    let group = NSCollectionLayoutGroup.horizontal(
//      layoutSize: groupSize,
//      subitem: fullPhotoItem,
//      count: 3
//    ) ~~ {
//      $0.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
//    }
//    //group.interItemSpacing = .fixed(margins)
//    let section = NSCollectionLayoutSection(group: group) ~~ {
//      $0.contentInsets = .init(top: margins / 2, leading: margins, bottom: margins / 2, trailing: margins)
//    }
//    let layout = UICollectionViewCompositionalLayout(section: section)
//    return layout
//  }()
//
//  private lazy var slideGesture = MultiGesture.slide
//  public private(set) lazy var collectionView = CollectionView(collectionViewLayout: collectionViewLayout)
//}








#if DEBUG
//extension Selection where T == LazyImage {
//  static func element(_ id: AnyHashable) -> Selection<LazyImage> {
//    let future = Future<UIImage, GenericError> { promise in
//      promise(.success(UIImage(color: .red)!))
//    }
//    return Selection<LazyImage>(
//      element: LazyImage(id: id, future: future.eraseToAnyPublisher()),
//      isSelected: false
//    )
//  }
//}
//
//struct CollectionView_Previews: PreviewProvider {
//  static var previews: some View {
//    RepresentableView(LazyImageCollection(store: .init(
//      initialState: .init(
//        canSelect: false,
//        elements: (1...10).map { Selection<LazyImage>.element(AnyHashable($0)) },
//        selectionCount: 0
//      ),
//      reducer: .empty,
//      environment: ()
//    )))
//  }
//}
#endif
