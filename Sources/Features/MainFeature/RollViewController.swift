import UIKit
import Engine
import ComposableArchitecture
import Combine

public typealias Roll = SelectionTracker<FilteredImage>

public final class RollViewController: UIViewController {
  private let store: Roll.Store
  private let viewStore: Roll.ViewStore
  
  public init(store: Roll.Store) {
    self.store = store
    self.viewStore = ViewStore(store)
    super.init(nibName: nil, bundle: nil)
    setupViews()
  }
  
  private func setupViews() {
    view.addSubview(collection)
    
    collection.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  private func subscribeToViewStore() {
  
  }
  
  private lazy var collection = LazyImageCollection<FilteredImage>(
    store: store.scope(
      state: { state in
        //print("scoping")
        let selection = state.selection
          .map { image -> Selection<LazyImage> in
            return image.map { $0.lazyImage(for: \.thumbnailImagePath.path) }
          }
        return .init(
          canSelect: state.canSelect,
          elements: selection,
          selectionCount: state.selectedElements.count
        )
      }
    )
  ) ~~ {
    $0.collectionView.backgroundColor = .dazecam.light
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
