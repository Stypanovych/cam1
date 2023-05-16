import UIKit
import Engine
import ComposableArchitecture
import Combine
import SwiftUI

public enum Paywall {
  public struct State: Equatable {
    public let user: User
    public let product: Product
    public let initialSelectedPayment: Payment?
    
    public init(
      user: User,
      product: Product,
      initialSelectedPayment: Payment?
    ) {
      self.user = user
      self.product = product
      self.initialSelectedPayment = initialSelectedPayment
    }
  }
  
  public enum Action: Equatable {
    case purchase(with: Payment)
    case restorePurchases
  }
  
  public typealias Store = ComposableArchitecture.Store<State, Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<State, Action>
}

public final class PaywallView: CombineView {
  private let store: Paywall.Store
  private let viewStore: Paywall.ViewStore
  private unowned var viewController: UIViewController
  
  init(store: Paywall.Store, viewController: UIViewController) {
    self.store = store
    self.viewStore = ViewStore(store)
    self.viewController = viewController
    super.init()
    setupViews()
    subscribeToViewStore()
  }
  
  private func setupViews() {
    backgroundColor = .dazecam.pink
  }
  
  private func subscribeToViewStore() {
    let importsLeftPublisher = viewStore.publisher.user.importsLeft
    
    importsLeftPublisher
      .first()
      .sink { [unowned self] importsLeft in
        self.layoutFor(importsLeft: importsLeft, animated: false)
      }
      .store(in: &cancellables)
    
    importsLeftPublisher
      .dropFirst()
      .sink { [unowned self] importsLeft in
        self.layoutFor(importsLeft: importsLeft, animated: true)
      }
      .store(in: &cancellables)
  }
  
  private func layoutFor(importsLeft: Int?, animated: Bool) {
    if let importsLeft = importsLeft {
      addToPaywallBar(
        importsLeft > 0 ? self.collapsedPaywallView : self.paywallView,
        animated: animated
      )
    }
  }
  
  private func addToPaywallBar(_ subview: UIView, animated: Bool) {
    guard !subviews.contains(subview) else { return }
    let subviewsToRemove = subviews
    let layout = { [unowned self] in
      subviewsToRemove.forEach {
        $0.snp.remakeConstraints { make in
          make.bottom.leading.trailing.equalToSuperview()
        }
      }
      addSubview(subview)
      subview.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
    }
    if animated {
      subview.isVisible = false
      UIView.animate(0.15) {
        subviewsToRemove.forEach { $0.alpha = 0 }
      }
      .animate(0.15) { [unowned self] _ in
        layout()
        self.superview?.layoutIfNeeded()
      }
      .animate(0.15) { _ in
        subview.isVisible = true
        subviewsToRemove.forEach { $0.removeFromSuperview() }
      }
      .sink { _ in }
      .store(in: &cancellables)
    } else {
      layout()
    }
  }

  private lazy var collapsedPaywallView = CollapsedPaywallView(
    store: store.scope(state: { $0.user.importsLeft ?? 0 }).actionless,
    action: { [unowned self] in self.addToPaywallBar(self.paywallView, animated: true) }
  )
    .environmentObject(Theme.shared)
    .uiview(viewController: viewController)
  
  private lazy var paywallView: UIView! = ExpandedPaywallView(
    store: store,
    dismissAction: { [unowned self] in self.addToPaywallBar(self.collapsedPaywallView, animated: true) }
  )
    .environmentObject(Theme.shared)
    .uiview(viewController: viewController)
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
