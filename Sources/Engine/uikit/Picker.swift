import UIKit
import ComposableArchitecture
import Combine
import DazeFoundation

public class Picker<T: Hashable, View: UIView>: CombineView {
  public struct State: Equatable {
    public var elements: [T]
    public var currentElement: T
    
    public init(
      elements: [T],
      currentElement: T
    ) {
      self.elements = elements
      self.currentElement = currentElement
    }
  }
  
  public typealias Action = T
  
  private let store: Store<State, Action>
  private let viewStore: ViewStore<State, Action>
  private let map: (T) -> Cell<View>.Configuration
  
  private let size: CGFloat
  private let spacing: CGFloat

  public init(
    store: Store<State, Action>,
    map: @escaping (T) -> Cell<View>.Configuration,
    size: CGFloat,
    spacing: CGFloat
  ) {
    self.store = store
    self.viewStore = ViewStore(store)
    self.map = map
    self.size = size
    self.spacing = spacing
    super.init()
    subscribeToViewStore()
    setupViews()
    setupInputs()
  }
  
  private func setupViews() {
    clipsToBounds = true
    addSubview(collection)
    collection.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    //collection.layoutIfNeeded()
  }
  
  private func setupInputs() {
    Publishers.CombineLatest(
      layoutSubviewsPublisher.first(),
      viewStore.publisher.currentElement.first()
    )
    //viewStore.publisher.currentElement.first()
      .sink { [unowned self] _, element in
        guard let indexPath = self.collection.indexPath(for: element) else { return }
        self.collection.scroll(to: indexPath.row, animated: false)
      }
      .store(in: &cancellables)
      
//    collection.didSelectPublisher
//      .sink { [unowned self] index in
//        guard let element = self.viewStore.elements[safe: index] else { return }
//        self.viewStore.send(element)
//      }
//      .store(in: &cancellables)
  }
  
  private func subscribeToViewStore() {
    viewStore.publisher.elements
      .sink { [unowned self] elements in
        let collectionViewElements: [CollectionView.Element<Cell<View>>] = elements.map { element in
          return .init(
            id: element,
            configure: { [unowned self] cell in
              cell.configure(with: self.map(element))
            },
            didSelect: { [unowned self] in self.viewStore.send(element) }
          )
        }
        self.collection.update(with: collectionViewElements)
      }
      .store(in: &cancellables)
    
    viewStore.publisher.currentElement.dropFirst()
      .sink { [unowned self] element in
        guard let indexPath = self.collection.indexPath(for: element) else { return }
        self.collection.scroll(to: indexPath.item, animated: true)
      }
      .store(in: &cancellables)
  }
  
  public private(set) lazy var collection = SegmentedCollectionView(direction: .horizontal, size: size, spacing: spacing) ~~ {
    $0.showsHorizontalScrollIndicator = false
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
