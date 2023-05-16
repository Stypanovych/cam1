import UIKit
import Engine
import ComposableArchitecture
import Combine
import SwiftUI
import EditFeature

public enum SelectState: Equatable {
  case disabled
  case enabled
  case selecting(Int)
}

public class MainViewController: ScrollViewController {
  private let store: Store<Main.State, Main.Action>
  private let viewStore: ViewStore<Main.State, Main.Action>
  
  let libraryViewController: LibraryViewController
  
  public init(store: Store<Main.State, Main.Action>) {
    let rollViewController = RollViewController(
      store: store.scope(
        state: \.roll,
        action: Main.Action.roll
      ))
    libraryViewController = LibraryViewController(
      store: store.scope(state: \.library, action: Main.Action.library)
    )
    self.store = store
    self.viewStore = ViewStore(store)
    super.init(
      viewControllers: [[rollViewController, libraryViewController]],
      startIndex: (0, 0)
    )
    setupViews()
    setupInputs()
    subscribeToViewStore()
  }
  
  private func setupInputs() {
    viewControllerPublisher
      .sink { [unowned self] vc in
        switch vc {
        case is RollViewController: self.viewStore.send(.setPage(.roll))
        case is LibraryViewController: self.viewStore.send(.setPage(.library))
        default: return
        }
      }
      .store(in: &cancellables)
    
    isScrollingPublisher
      .sink { [unowned self] isScrolling in
        self.mainBar.isUserInteractionEnabled = !isScrolling
      }
      .store(in: &cancellables)
    
    lensButton.gesture()
      .sink { [unowned self] _ in
        self.viewStore.send(.navigateToCamera)
      }
      .store(in: &cancellables)
  }
  
  private func subscribeToViewStore() {
    var editViewController: EditViewController?
    store.scope(state: \.edit, action: Main.Action.edit)
      .ifLet(
        then: { [unowned self] in
          editViewController = EditViewController(store: $0)
          editViewController?.viewDidDisappearPublisher
            .sink { [unowned self] in
              guard viewStore.edit != nil else { return }
              self.viewStore.send(.edit(.onDismiss))
            }
            .store(in: &cancellables)
          self.view.window?.rootViewController?.present(editViewController!, animated: true, completion: nil)
        },
        else: {
          editViewController?.dismiss(animated: true, completion: nil)
        }
      )
      .store(in: &cancellables)
    
    viewStore.publisher.page
      .sink { [unowned self] page in
        switch page {
        case .library: self.scrollTo(col: 1)
        case .roll: self.scrollTo(col: 0)
        }
      }
      .store(in: &cancellables)
    
    viewStore.publisher.notification
      .sink { [unowned self] notification in
        // remove any outstanding notifications
        if let notificationView = self.notificationView {
          self.remove(notificationView: notificationView, from: self.bar)
          self.notificationView = nil
        }
        if let notification = notification {
          self.notificationView = self.add(notification: notification, onto: self.bar)
          self.viewStore.send(.setNotification(nil))
        }
      }
      .store(in: &cancellables)
    
//    viewStore.publisher.library
//      .map(\.enabled)
//      .sink { [unowned self] enabled in
//        self.libraryViewController.usageLabel.isHidden = enabled
//      }
//      .store(in: &cancellables)
    
    viewStore.publisher.fetching
      .sink { fetching in
        let loadingView = self.libraryViewController.loadingView
        fetching ? loadingView.startAnimating() : loadingView.stopAnimating()
      }
      .store(in: &cancellables)
    
    store.scope(state: \.paywall, action: Main.Action.paywall).ifLet(
      then: { [unowned self] in self.libraryViewController.addPaywall(store: $0) },
      else: { [unowned self] in self.libraryViewController.removePaywall() }
    )
    .store(in: &cancellables)
  }
  
  private func setupViews() {
    let topBar = UIView() ~~ {
      $0.backgroundColor = .dazecam.light
      Theme.shared.shadow.apply(to: $0)
    }
    view.addSubview(topBar)
    view.addSubview(bar)
    topBar.addSubview(lensButton)
    topBar.addSubview(tabBar)
    bar.addSubview(mainBar)
    
    topBar.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
    }
    
    tabBar.snp.makeConstraints { make in
      make.bottom.leading.trailing.equalToSuperview()
      make.top.equalTo(lensButton.snp.bottom).offset(Theme.shared.margins)
    }

    bar.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-Theme.shared.barHeight)
    }

    lensButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(Theme.shared.safeAreaInsets.top + Theme.shared.margins)
      make.width.height.equalTo(Theme.shared.unit * 4)
    }
    
    mainBar.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(topBar.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(bar.snp.top)
    }
  }
  
  private var notificationView: UIView?
  
  private lazy var lensButton = LensButton()
  
  private lazy var tabBar = TabBar(
    titles: ["DEVELOPED", "UNDEVELOPED"],
    positionPublisher: scrollPublisher
      .map(\.col)
      //.print()
      .eraseToAnyPublisher(),
    selected: { [unowned self] index in self.scrollTo(col: index) }
  )
    .environmentObject(Theme.shared)
    .uiview(viewController: self)

  private lazy var bar = UIView() ~~ {
    $0.backgroundColor = .dazecam.light
    Theme.shared.shadow.apply(to: $0)
  }

  private lazy var mainBar = MainBar(store: store.scope(
    state: { state in
      let selectState: SelectState = {
        switch (state.page, state.selecting) {
        case (.library, true):
          return .selecting(state.library.value?.selectedImages.count ?? 0)
        case (.library, false):
          if
            let importsLeft = state.user.importsLeft,
            importsLeft <= 0
          {
            return .disabled
          }
          return (state.library.value?.selectedAlbum?.images.count ?? 0) > 0 ? .enabled : .disabled
        case (.roll, true):
          return .selecting(state.roll.selectedElements.count)
        case (.roll, false):
          return state.roll.elements.count > 0 ? .enabled : .disabled
        }
      }()
      let optionsVisible: Bool = {
        guard
          case let .selecting(selectionCount) = selectState,
          selectionCount > 0
        else { return false }
        return true
      }()
      return .init(
        imageOptions: .init(
          optionsVisible: optionsVisible,
          downloadOptions: state.downloadOptions
        ),
        selectState: selectState,
        mainPage: state.page,
        libraryPage: state.library.value?.page
      )
    },
    action: { action in
      switch action {
      case let .main(mainAction): return mainAction
      case let .setSelectEnabled(enabled): return .setSelectEnabled(enabled)
      }
    }
  ))
    .environmentObject(Theme.shared)
    .uiview(viewController: self)

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

struct MainBar: View {
  struct ViewState: Equatable {
    var imageOptions: ImageOptionsViewState
    var selectState: SelectState
    var mainPage: Main.Page
    var libraryPage: Library.Page?
  }
  
  enum Action {
    case setSelectEnabled(Bool)
    case main(Main.Action)
  }
  
  typealias Store = ComposableArchitecture.Store<ViewState, Action>
  typealias ViewStore = ComposableArchitecture.ViewStore<ViewState, Action>
  
  let store: Store
  
  @EnvironmentObject private var theme: Theme
  
  @ViewBuilder
  func roll(_ viewStore: ViewStore) -> some View {
    ImageOptionsView(store: store.scope(state: \.imageOptions, action: { .main(.image($0)) })) {
      DazeButton("CANCEL") { viewStore.send(.setSelectEnabled(false)) }
    }
  }
  
  @ViewBuilder
  func library(_ viewStore: ViewStore) -> some View {
    DazeButton("CANCEL") { viewStore.send(.setSelectEnabled(false)) }
    Spacer()
    if
      case let .selecting(selectionCount) = viewStore.state.selectState,
      selectionCount > 0
    {
      DazeButton("DEVELOP") { viewStore.send(.main(.import)) }
    }
  }
  
  func select(_ viewStore: ViewStore) -> some View {
    DazeButton("SELECT") { viewStore.send(.setSelectEnabled(true)) }
  }
  
//  @ViewBuilder
//  func back(_ viewStore: ViewStore) -> some View {
//    DazeButton(image: .dazecam.back) { viewStore.send(.main(.library(.showAlbums))) }
//      .frame(height: 13)
//    Margin(2)
//  }
  
  var body: some View {
    WithViewStore(store) { viewStore in
      HStack {
        Margin()
        switch viewStore.state.mainPage {
        case .roll:
          switch viewStore.state.selectState {
          case .selecting:
            roll(viewStore)
          case .enabled:
            select(viewStore)
            Spacer()
          case .disabled:
            EmptyView()
          }
        case .library:
          switch viewStore.state.selectState {
          case .selecting:
            library(viewStore)
          case .enabled:
            select(viewStore)
            Spacer()
          case .disabled:
            Spacer()
          }
        }
//        switch (viewStore.state.selectState, viewStore.state.page) {
//        case (.selecting, .roll):
//          roll(viewStore)
//        case (.selecting, .library):
//          back(viewStore)
//          library(viewStore)
//        case let (.enabled, page):
//          if page == .library { back(viewStore) }
//
//        case (.disabled, .library):
//
//          Spacer()
//        case (.disabled, .roll):
//          EmptyView()
//        }
        Margin()
      }
    }.animation(.easeIn(duration: 0.15))
  }
}

struct TabBar: View {
  let titles: [String]
  let positionPublisher: AnyPublisher<CGFloat, Never>
  let selected: (Int) -> Void
  
  @State private var textWidth: CGFloat?
  @State private var underlineOffset: CGFloat = 0
  
  @EnvironmentObject private var theme: Theme
  
  private var titleStack: some View {
    HStack {
      ForEach(0..<titles.count, id: \.self) { index in
        let opacity: CGFloat = max(1 / (1 + abs(CGFloat(index) - underlineOffset)), 0.5)
        Text(titles[index])
          .font(theme.font.main.black.large.uiFont.swiftui)
          .frame(maxWidth: .infinity)
          .foregroundColor(theme.color.dark.swiftui.opacity(opacity))
          .onTapGesture {
            selected(index)
          }
      }
    }
  }
  
  private var underline: some View {
    Color.clear
      .frame(height: 3)
      .overlay(
        GeometryReader { proxy in
          let width = proxy.size.width / CGFloat(titles.count)
          theme.color.dark.swiftui
            .frame(
              width: width,
              height: proxy.size.height
            )
            .position(
              x: width / 2 + underlineOffset * width,
              y: proxy.size.height / 2
            )
        }
      )
  }
  
  var body: some View {
    VStack(spacing: 0) {
      titleStack
      Margin(0.5)
      underline
    }
    .onReceive(positionPublisher) { position in
      //print("fuck \(position)")
      underlineOffset = position
    }
    .animation(.easeIn(duration: 0.3), value: underlineOffset) // hack: scrollview animation doesn't call scrollViewDidScroll
    
  }
}

#if DEBUG
let mainBarReducer = Reducer<MainBar.ViewState, MainBar.Action, Void> { state, action, _ in
  switch action {
  case let .setSelectEnabled(enabled):
    state.selectState = enabled ? .enabled : .disabled
    return .none
  case .main:
    return .none
  }
}

func mainBarStore() -> MainBar.Store {
  .init(
    initialState: .init(
      imageOptions: .init(optionsVisible: true, downloadOptions: ImageOption.Download.all),
      selectState: .selecting(1),
      mainPage: .roll,
      libraryPage: .albums
    ),
    reducer: .empty,
    environment: ()
  )
}

struct TabBarPreview: PreviewProvider {
  static var previews: some View {
    TabBar(titles: ["developed", "undeveloped"], positionPublisher: Just(0).eraseToAnyPublisher(), selected: { _ in })
  }
}

//struct MainBarView_Previews: PreviewProvider {
//  static var previews: some View {
//    MainBar(store: mainBarStore()).environmentObject(Theme.shared)
//  }
//}
#endif


