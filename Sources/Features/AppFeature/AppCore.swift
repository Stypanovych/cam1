import ComposableArchitecture
import Combine
import UIKit
import Engine
import CameraFeature
import EditFeature
import MainFeature
//import XCTest

// scope to just State in views ...
//struct StateEnv<State: Equatable, Env>: Equatable {
//  var state: State
//  let env: Env
//}

public enum App {
  public enum Page: Equatable {
    case camera
    case main
  }
  
  public struct State: Equatable {
    public var page: App.Page
    public var user: User
    //public var library: Usage<Library.State> = .enabled(.empty)
    
    private var _main: Main.State
    public var main: Main.State {
      get {
        .init(
          page: _main.page,
          user: user,
          selectEnabled: _main.selecting,
          library: _main.library,
          edit: _main.edit,
          rollSelection: _main.rollSelection,
          //librarySelection: _main.librarySelection,
          notification: _main.notification,
          fetching: _main.fetching,
          product: _main.product,
          env: env.map(\.main)
        )
      }
      set {
        user = newValue.user
        _main = newValue
      }
    }

    @Substate public var capture: Capture.State
    
    @EquatableNoop
    public var env: SystemEnvironment<Environment>
    
    public init(
      page: App.Page = .camera,
      user: User = .default,
      env: SystemEnvironment<Environment>
    ) {
      self.page = page
      self.user = user
      self._main = .init(
        user: user,
        notification: nil,
        fetching: false,
        product: nil,
        env: env.map(\.main)
      )
      self._capture = Substate(Capture.State(
        cameraSettings: .init(flash: .off, orientation: .back),
        env: env.map(\.capture))
      )
      self._env = EquatableNoop(env)
    }
  }

  public enum Action: Equatable {
    case onAppear
    case setPage(App.Page)
    //case photoLibrary(authorized: Bool)
    case purchases(Set<Purchase>)
    case product(Product)
    case albums(Usage<[PhotoLibrary.Album]>)
    case persist(User)
    //case binding(BindingAction<State>)
    
    case error(EquatableError)
    
    case main(Main.Action)
    case capture(Capture.Action)
  }
  
  public struct Environment {
    public var factory: FilteredImage.Factory
    public var productStore: ProductStore
    public var persistedUser: Persisted<User>
    public var photoLibrary: PhotoLibrary
    public var camera: Camera
    public var downloader: MediaDownloader<LocalImage>
    
    public var capture: Capture.Environment {
      .init(camera: camera)
    }
    
    public var main: Main.Environment {
      .init(
        factory: factory,
        productStore: productStore,
        downloader: downloader
      )
    }
    
    public init(
      factory: FilteredImage.Factory,
      productStore: ProductStore,
      persistedUser: Persisted<User>,
      photoLibrary: PhotoLibrary,
      camera: Camera,
      downloader: MediaDownloader<LocalImage>
    ) {
      self.factory = factory
      self.productStore = productStore
      self.persistedUser = persistedUser
      self.photoLibrary = photoLibrary
      self.camera = camera
      self.downloader = downloader
    }
  }
  
  public static let reducer: Reducer<State, Action, Void> = .combine(
    Main.reducer.pullback(
      state: \.main,
      action: /Action.main,
      environment: { _ in }
    ),
    Capture.reducer.pullback(
      state: \.capture,
      action: /Action.capture,
      environment: { _ in }
    ),
    .init { state, action, _ in
      let env = state.env
      
      switch action {
      case .onAppear:
        state.user.openedApp = true
        state.main.fetching = true
        return env.purchases().eraseToEffect()

      case let .purchases(purchases):
        return .concatenate(
          Effect(value: .main(.purchaseCompleted(purchases))),
          state.user.purchasedPremium ? env.setupPhotoLibrary().eraseToEffect() : env.product().eraseToEffect()
        )
        
      case let .main(.purchaseCompleted(purchases)):
        state.user.purchases = state.user.purchases.union(purchases)
        return .none
        
      case let .product(product):
        state.main.product = product
        return env.setupPhotoLibrary().eraseToEffect()
        
      case let .capture(.receivedPhoto(image)):
        return Effect(value: .main(.filter(image)))

      case let .albums(albums):
        state.main.fetching = false
        // TODO: uniqueElements can crash if returns two of the same album
        // TODO: Album cover does not change when the contents change but the id is the same
        state.main.library = albums.map { albums in
          return update(state.main.library.value ?? .empty) { libraryState in
            libraryState.albums = IdentifiedArrayOf(uniqueElements: albums)
            if let selectedAlbum = libraryState.selectedAlbum { libraryState = libraryState.select(id: selectedAlbum.album.id) }
          }
        }
        return .none

      case let .setPage(page):
        print(page)
        state.page = page
        return .none
        
      case let .persist(user):
        print("persisted user")
        return env.persistedUser.store(user)
        //.subscribe(on: env.storageScheduler)
        .receive(on: env.mainScheduler)
        .fireAndForget()
        //.eraseToEffect()
        
      case .capture(.navigateToMain):
        return Effect(value: .setPage(.main))
        
      case .main(.navigateToCamera):
        return Effect(value: .setPage(.camera))
          
      case .capture, .main, .error:
        return .none
      }
    }
  )
  .persist()
//    .debug()
    //.debug(actionFormat: .labelsOnly)
  
  public typealias Store = ComposableArchitecture.Store<State, Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<State, Action>
}
      
extension Reducer where State == App.State, Action == App.Action {
  func persist() -> Reducer<App.State, App.Action, Environment> {
    return .init { state, action, environment in
      let previousUserState = state.user
      var effect = self.run(&state, action, environment)
      if state.user != previousUserState {
        effect = .merge(
          effect,
          Effect(value: .persist(state.user))
        )
          //.debounce(id: UserPersistanceIdentifier(), for: 1, scheduler: environment.mainQueue))
      }
      return effect
    }
  }
}


extension SystemEnvironment where Environment == App.Environment {
  // get purchases
  // if no purchases get product
  // setupPhotoLibrary
  
  func product() -> AnyPublisher<App.Action, Never> {
    self.productStore.product()
      .replaceError(with: .premium(payments: []))
      .receive(on: mainScheduler)
      .map(App.Action.product)
      .eraseToAnyPublisher()
  }
  
  func purchases() -> AnyPublisher<App.Action, Never> {
    self.productStore.purchases()
      .replaceError(with: [])
      //.delay(for: 2, scheduler: mainScheduler) // TODO
      .receive(on: mainScheduler)
      .map(App.Action.purchases)
      .eraseToAnyPublisher()
  }
  
  func setupPhotoLibrary() -> AnyPublisher<App.Action, Never> {
    self.photoLibrary.authorize
      .flatMap { authorized -> AnyPublisher<App.Action, Never>  in
        if authorized {
          return Just(self.photoLibrary.fetch())
            .map { App.Action.albums(.enabled($0)) }
            .eraseToAnyPublisher()
        } else {
          return Just(App.Action.albums(Usage<[PhotoLibrary.Album]>.disabled))
            .eraseToAnyPublisher()
        }
      }
      .receive(on: mainScheduler)
      .eraseToAnyPublisher()
  }
}
