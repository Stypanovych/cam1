import UIKit
import Engine
import ComposableArchitecture
import Combine
import CameraFeature
import MainFeature
import EditFeature

//protocol PageView {
//  var page: AppPage { get }
//}
//
//extension CameraViewController: PageView {
//  var page: AppPage { .camera }
//}
//
//extension RollViewController: PageView {
//  var page: AppPage { .roll }
//}
//
//extension LibraryViewController: PageView {
//  var page: AppPage { .library }
//}

//extension MainViewController.Action {
//  var app: App.Action {
//    switch self {
//    case let .main(action): return .main(action)
//    case let .paywall(action): return .paywall(action)
//    }
//  }
//}
//
//extension MainViewController.State {
//  init(appState: App.State) {
//    self.init(
//      paywall: .init(
//        user: appState.user,
//        product: .premium,
//        initialSelectedPayment: .premiumYearly
//      ),
//      main: appState.main
//    )
//  }
//}

public class AppViewController: ScrollViewController {
  private let store: App.Store
  private let viewStore: App.ViewStore
  
  private let mainViewController: MainViewController

    public init(store: App.Store) {
    self.store = store
    self.viewStore = ViewStore(store)
    let cameraViewController = CameraViewController(store: store.scope(state: \.capture, action: App.Action.capture))
    self.mainViewController = MainViewController(store: store.scope(
      state: \.main,
      action: App.Action.main
    ))
    super.init(
      viewControllers: [
        [cameraViewController],
        [mainViewController]
      ],
      startIndex: (0, 0)
    )
    setupViews()
    setupInputs()
    subscribeToViewStore()
  }
  
  func setupViews() {
    scrollView.shouldRecognizeSimultaneously { gestureRecognizer, otherGestureRecognizer in
      if let view = otherGestureRecognizer.view as? UICollectionView  {
        return view.contentOffset.y <= 0 //&& self.scrollView.contentOffset.y > 0
      }
      return false
    }
    scrollView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  func setupInputs() {
    viewDidAppearPublisher
      .sink { [unowned self] in
        self.viewStore.send(.onAppear)
      }
      .store(in: &cancellables)
    
    viewControllerPublisher
      .sink { [unowned self] vc in
        switch vc {
        case is CameraViewController: self.viewStore.send(.setPage(.camera))
        case is MainViewController: self.viewStore.send(.setPage(.main))
        default: break
        }
      }
      .store(in: &cancellables)
  }
  
  private func subscribeToViewStore() {
    viewStore.publisher.page
      .sink { [unowned self] page in
        switch page {
        case .main: self.scrollTo(row: 1)
        case .camera: self.scrollTo(row: 0)
        }
      }
      .store(in: &cancellables)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
