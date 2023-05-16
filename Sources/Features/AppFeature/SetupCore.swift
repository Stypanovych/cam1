import ComposableArchitecture
import Combine
import Engine
import CoreImage
import UIKit

public enum Setup {
  public struct State: Equatable {
    public var app: App.State?
    
    public init() {
      app = nil
    }
  }
  
  public enum Action {
    case onAppear
    case setupComplete(App.State?)
    case app(App.Action)
  }
  
  public struct Environment {
    public var productStore: ProductStore
    public var persistedUser: Persisted<User>
    public var photoLibrary: PhotoLibrary
    public var camera: Camera
    public var downloader: MediaDownloader<LocalImage>
    
    public init (
      productStore: ProductStore,
      persistedUser: Persisted<User>,
      photoLibrary: PhotoLibrary,
      camera: Camera,
      downloader: MediaDownloader<LocalImage>
    ) {
      self.productStore = productStore
      self.persistedUser = persistedUser
      self.photoLibrary = photoLibrary
      self.camera = camera
      self.downloader = downloader
    }
  }

  public static let reducer = Reducer<State, Action, SystemEnvironment<Environment>>.combine(
    App.reducer.optional().pullback(
      state: \.app,
      action: /Action.app,
      environment: { _ in }
    ),
    .init { state, action, env in
      switch action {
      case .onAppear:
        return env.setup()
          .receive(on: env.mainScheduler)
          .map(Setup.Action.setupComplete)
          .catch { _ in Just(Setup.Action.setupComplete(nil)) }
          .eraseToEffect()
        
      case let .setupComplete(appState):
        state.app = appState
        return .none
        
      case .app:
        return .none
      }
    }
  )
  
  public typealias Store = ComposableArchitecture.Store<State, Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<State, Action>
}

extension SystemEnvironment where Environment == Setup.Environment {
  func setup() -> AnyPublisher<App.State, Error> {
    return self.persistedUser.fetch().eraseToAnyPublisher()
      .map { user -> App.State in
        App.State(
          user: user,
          env: map {
            .init(
              factory: .persistedToDisk(filter: filter),
              productStore: $0.productStore,
              persistedUser: $0.persistedUser,
              photoLibrary: $0.photoLibrary,
              camera: $0.camera,
              downloader: $0.downloader
            )
          }
        )
      }
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
}
