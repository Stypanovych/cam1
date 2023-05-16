import UIKit
import Engine
import ComposableArchitecture
import Combine
import SwiftUI

public final class LibraryViewController: CombineViewController {
//  private let libraryImagesStore: LibraryImages.Store
//  private let libraryAlbumsStore: LibraryAlbums.Store
  public typealias Store = ComposableArchitecture.Store<Usage<Library.State>, Library.Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<Usage<Library.State>, Library.Action>
  
  private let store: Store
  private let viewStore: ViewStore
  
  public init(store: Store) {
    self.store = store
    self.viewStore = ViewStore(store)
    super.init()
    setupViews()
    subscribeToViewStore()
  }
  
  private func setupViews() {
    view.backgroundColor = .dazecam.light
    
    collection.addSubview(imageCollection)
    collection.addSubview(photoCollectionNavigationBar)
    view.addSubview(collection)
    
    view.addSubview(albumCollection)
    view.addSubview(loadingView)
    view.addSubview(usageLabel)
    
    loadingView.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
    
    collection.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    imageCollection.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
    }
    
    photoCollectionNavigationBar.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.bottom.equalTo(imageCollection.snp.top)
      make.height.equalTo(Theme.shared.barHeight)
    }
    
    albumCollection.snp.makeConstraints { make in
      make.edges.equalTo(collection)
    }
    
    usageLabel.snp.makeConstraints { make in
      make.center.equalTo(collection)
    }
  }
  
  private func subscribeToViewStore() {
    viewStore.publisher
      .map(\.enabled)
      .sink { [unowned self] enabled in
        self.usageLabel.isHidden = enabled
      }
      .store(in: &cancellables)
    
    viewStore.publisher
      .sink { usage in
        switch usage {
        case .disabled:
          self.collection.isVisible = false
          self.albumCollection.isVisible = false
        case let .enabled(library):
          if let _ = library.selectedAlbum {
            self.collection.isVisible = true
            self.albumCollection.isVisible = false
          } else {
            self.collection.isVisible = false
            self.albumCollection.isVisible = true
          }
        }
      }
      .store(in: &cancellables)
  }

  private var paywall: UIView?
  
  func addPaywall(store: Paywall.Store) {
    let paywallView = PaywallView(store: store, viewController: self)
    view.addSubview(paywallView)
    
    paywallView.snp.makeConstraints { make in
      make.bottom.leading.trailing.equalToSuperview()
      make.top.equalTo(collection.snp.bottom)
    }
    collection.snp.remakeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
    }
    // animate
    collection.alpha = 0
    paywallView.alpha = 0
    UIView.animate(2) { [unowned self] in
      self.collection.alpha = 1
      paywallView.alpha = 1
    }
    .sink { _ in }
    .store(in: &cancellables)
    
    self.paywall = paywallView
  }
  
  func removePaywall() {
    guard let paywall = paywall else { return }

    UIView.animate(0.3) {
      paywall.subviews.forEach { $0.alpha = 0 }
    }
    .animate(0.3) { [unowned self] _ in
      paywall.snp.remakeConstraints { make in
        make.bottom.leading.trailing.equalToSuperview()
        make.top.equalTo(collection.snp.bottom)
        make.height.equalTo(0)
      }
      self.view.layoutIfNeeded()
    }
    .sink { [unowned self] _ in
      self.collection.snp.remakeConstraints { make in
        make.top.bottom.leading.trailing.equalToSuperview()
      }
      paywall.removeFromSuperview()
    }
    .store(in: &cancellables)
  }
  
  private(set) lazy var usageLabel = UILabel() ~~ {
    $0.text = "Allow photos access in settings to view and develop them here"
    $0.textColor = .dazecam.dark.withAlphaComponent(0.3)
    $0.font = .dazecam.main.mid.black.uiFont
    $0.numberOfLines = 0
  }
  
  private(set) lazy var photoCollectionNavigationBar = PhotoCollectionNavigationBar(
    backAction: { [unowned self] in viewStore.send(.showAlbums) },
    store: store.scope(state: { $0.value?.selectedAlbum?.album.name ?? "" }).actionless
  )
  .environmentObject(Theme.shared)
  .uiview(viewController: self) ~~ {
    $0.backgroundColor = .dazecam.light
    Theme.shared.shadow.apply(to: $0)
  }
  
  private(set) lazy var collection = UIView()
  
  // performance from scoping from MainStore?
  private(set) lazy var imageCollection = LazyImageCollection<PhotoLibrary.Image>(
    store: store
      .scopeDeduping(
        state: { state in
          guard let libraryImages = state.value?.libraryImages else { return .disabled }
          return .init(
            canSelect: libraryImages.canSelect,
            elements: libraryImages.selection
              .map { selection in
                selection.map { $0.lazyImage(size: .custom(CGSize(width: 200, height: 200))) }
              },
            selectionCount: libraryImages.selectedElements.count
          )
        },
        action: { .libraryImages($0) }
      )
  ) ~~ {
    $0.collectionView.backgroundColor = .dazecam.light
  }
  
  private(set) lazy var albumCollection = AlbumCollection(
    store: store
      .scopeDeduping(
        state: { state in
          guard let albums = state.value?.albums else { return [] }
          return albums.elements
        },
        action: Library.Action.selectAlbum
      )
  ) ~~ {
    $0.collectionView.backgroundColor = .dazecam.light
  }
  
  private(set) lazy var loadingView = UIActivityIndicatorView() ~~ {
    $0.color = .dazecam.dark.withAlphaComponent(0.5)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

struct PhotoCollectionNavigationBar: View {
  typealias ViewState = String
  
  let backAction: () -> Void
  let store: Store<ViewState, Never>
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    WithViewStore(store) { viewStore in
      ZStack {
        HStack {
          Margin()
          DazeButton(image: .dazecam.back, action: backAction)
            .frame(height: 13)
          Spacer()
        }
        Text(viewStore.state)
          .foregroundColor(theme.dark.swiftui)
          .font(theme.font.main.large.black.uiFont.swiftui)
      }
      .background(theme.light.swiftui)
    }
  }
}

struct CollapsedPaywallView: View {
  let store: Store<Int, Never>
  let action: () -> Void
  
  @EnvironmentObject var theme: Theme
  
  init(
    store: Store<Int, Never>,
    action: @escaping () -> Void
  ) {
    self.store = store
    self.action = action
  }
  
  var body: some View {
    WithViewStore(store) { viewStore in
      HStack {
        Text("You have \(viewStore.state) develops left")
          .foregroundColor(theme.dark.swiftui)
          .font(theme.main.mid.black.uiFont.swiftui)
        Spacer()
        DazeButton("GET UNLIMITED", action: action)
      }
      .padding()
    }
  }
}

struct ExpandedPaywallView: View {
  let store: Paywall.Store
  let dismissAction: () -> Void
  
  @EnvironmentObject var theme: Theme
  @State private var payment: Payment?
  
  @State private var buttonMaxWidth: CGFloat?
  
  init(
    store: Paywall.Store,
    dismissAction: @escaping () -> Void
  ) {
    self.store = store
    self.dismissAction = dismissAction
    _payment = State(initialValue: ViewStore(store).initialSelectedPayment)
  }

  func paymentOptions(_ viewStore: Paywall.ViewStore) -> some View {
    HStack(spacing: theme.unit) {
      ForEach(viewStore.state.product.acceptedPayments, id: \.self) { payment in
        let selected = (self.payment) == payment
        Button(payment.costDescription) { self.payment = payment }
          .background(GeometryReader { geometry in
            Color.clear.preference(
              key: ButtonWidthPreferenceKey.self,
              value: geometry.size.width
            )
          })
          .frame(width: buttonMaxWidth)
          .padding(theme.unit)
          .font(theme.main.small.black.uiFont.swiftui)
          .foregroundColor(theme.dark.swiftui)
          .background(theme.light.swiftui)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          .opacity(selected ? 1 : 0.4)
      }
    }
    .onPreferenceChange(ButtonWidthPreferenceKey.self) {
      buttonMaxWidth = $0
    }
  }
  
  func buttons(_ viewStore: Paywall.ViewStore) -> some View {
    let buttonCount = CGFloat(viewStore.product.acceptedPayments.count)
    let width = (buttonMaxWidth ?? 0) * buttonCount + (3 * buttonCount - 1) * theme.unit
    return Group {
     if let payment = payment {
        paymentOptions(viewStore)
        Margin(0.5)
        Text(payment.trialDescription.map { _ in "START FREE TRIAL" } ?? "BUY")
          .padding(theme.margins)
          .frame(width: width)
          .background(theme.dark.swiftui)
          .font(theme.main.large.black.uiFont.swiftui)
          .foregroundColor(theme.light.swiftui)
          .clipShape(RoundedRectangle(cornerRadius: theme.unit))
          .hapticTap {
            viewStore.send(.purchase(with: payment))
          }
      } else {
        Text("An error occurred finding payment options")
          .font(theme.main.large.black.uiFont.swiftui)
          .foregroundColor(theme.red.swiftui)
      }
    }
  }

  var body: some View {
    WithViewStore(store) { (viewStore: Paywall.ViewStore) in
      VStack {
        HStack {
          Spacer()
          DazeButton(image: .dazecam.x, action: dismissAction)
            .frame(width: 10, height: 10)
        }
        Group {
          Margin()
          Text("To continue developing photos and gain full access to all features, you must purchase")
            .foregroundColor(theme.color.dark.swiftui)
            .font(theme.main.mid.black.uiFont.swiftui)
          Margin()
          Text("PREMIUM")
            .foregroundColor(theme.color.dark.swiftui)
            .font(theme.main.large.black.uiFont.swiftui)
          Margin()
          Text(payment?.trialDescription.map { "Get a \($0) free trial then pay" } ?? "")
            .foregroundColor(theme.color.dark.swiftui)
            .font(theme.main.mid.black.uiFont.swiftui)
          Margin()
        }
        buttons(viewStore)
        Margin()
        Text(payment?.trialDescription.map { "Cancel anytime. You will be charged at the completion of the \($0) trial." } ?? "")
          .foregroundColor(theme.dark.swiftui)
          .font(theme.main.small.medium.uiFont.swiftui)
        Margin(0.5)
        //
        HStack {
          Text("Terms of Use")
            .underline()
            .foregroundColor(theme.dark.swiftui)
            .font(theme.main.small.black.uiFont.swiftui)
            .hapticTap {
              UIApplication.shared.open(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
          Text("Restore Purchases")
            .underline()
            .foregroundColor(theme.dark.swiftui)
            .font(theme.main.small.black.uiFont.swiftui)
            .hapticTap {
              viewStore.send(.restorePurchases)
            }
          Text("Privacy Policy")
            .underline()
            .foregroundColor(theme.dark.swiftui)
            .font(theme.main.small.black.uiFont.swiftui)
            .hapticTap {
              UIApplication.shared.open(URL(string: "https://vine-iodine-648.notion.site/DAZE-CAM-Privacy-Policy-ee6935f437144ad28dd088855e362d3f")!)
            }
        }
      }
      .frame(maxWidth: .infinity)
    }
    .padding(theme.margins)
  }
  
  private struct ButtonWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      value = max(value, nextValue())
    }
  }
}

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
  static var previews: some View {
    //EmptyView()
    CollapsedPaywallView(
      store: .init(
        initialState: 3,
        reducer: .empty,
        environment: ()
      ),
      action: {}
    )
      .environmentObject(Theme.shared)
    ExpandedPaywallView(store: .init(
      initialState: .init(
        user: .default,
        product: .mockPremium,
        initialSelectedPayment: .mockPremiumOneTime
      ),
      reducer: .empty,
      environment: ()
    ), dismissAction: {})
      .environmentObject(Theme.shared)
  }
}
#endif
