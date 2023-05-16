import UIKit
import Engine
import ComposableArchitecture
import Combine

public final class SetupViewController: CombineViewController {
  private let store: Setup.Store
  private let viewStore: Setup.ViewStore
  
  private var appViewController: AppViewController?
  
  public init(
    store: Setup.Store,
    viewStore: Setup.ViewStore
  ) {
    self.store = store
    self.viewStore = viewStore
    super.init()
    setupViews()
    setupInputs()
    subscribeToViewStore()
  }
  
  func setupViews() {
    view.backgroundColor = .dazecam.dark
    view.addSubview(loadingView)
    
    loadingView.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
    
    loadingView.startAnimating()
  }
  
  func setupInputs() {
    viewDidAppearPublisher
      .sink { [unowned self] in
        self.viewStore.send(.onAppear)
      }
      .store(in: &cancellables)
  }
  
  private func subscribeToViewStore() {
    store.scope(state: \.app, action: Setup.Action.app)
      .ifLet { [unowned self] store in
        let appViewController = AppViewController(store: store)
        defer { self.appViewController = appViewController }
        self.view.addSubview(appViewController.view)
        appViewController.view.snp.makeConstraints { make in
          make.edges.equalToSuperview()
        }
        appViewController.view.isVisible = false
        appViewController.view.layoutIfNeeded()
        UIView.animate(0.3) {
          appViewController.view.isVisible = true
        }
        .sink { _ in }
        .store(in: &cancellables)
      }
      .store(in: &cancellables)
  }
  
  private lazy var loadingView = UIActivityIndicatorView() ~~ {
    $0.color = .dazecam.light
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
