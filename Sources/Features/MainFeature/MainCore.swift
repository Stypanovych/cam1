import ComposableArchitecture
import Engine
import CoreImage
import Combine
import EditFeature
import UIKit
import StoreKit

public typealias LibraryImages = SelectionTracker<PhotoLibrary.Image>
public typealias LibraryAlbums = SelectionTracker<PhotoLibrary.Album>

public enum Main {
  public struct State: Equatable {
    public var page: Page
    public var user: User
    //public var library: Usage<Library>
    public var selecting: Bool
    public var rollSelection: Set<FilteredImage>
    //public var librarySelection: Set<PhotoLibrary.Image>
    public var notification: Engine.Notification?
    public var fetching: Bool
    
    public let downloadOptions = ImageOption.Download.all
    
    @EquatableNoop
    public var env: SystemEnvironment<Environment>
    
    public var _edit: Edit.State?
    public var edit: Edit.State? {
      get {
        _edit.map {
          .init(
            elements: user.images,
            presets: user.presets,
            currentElementId: $0.currentElementId,
            editSession: $0.editSession,
            notification: $0.notification,
            isSaving: $0.isSaving,
            env: env.map(\.edit)
          )
        }
      }
      set {
        newValue.map { user.images = $0.elements }
        newValue.map { user.presets = $0.presets }
        _edit = newValue
      }
    }
    
    public var roll: Roll.State {
      get {
        .init(
          canSelect: selecting && page == .roll,
          selectedElements: rollSelection,
          elements: user.images
        )
      }
      set {
        rollSelection = newValue.selectedElements
      }
    }
    
    private var _library: Usage<Library.State>
    public var library: Usage<Library.State> {
      get {
        _library.map {
          .init(
            albums: $0.albums,
            canSelect: selecting && page == .library,
            selectionCapacity: user.importsLeft,
            selectedImages: $0.selectedImages,
            selectedAlbum: $0.selectedAlbum
          )
        }
      }
      set {
        _library = newValue
      }
    }
//    public var libraryImages: LibraryImages.State {
//      get {
//        .init(
//          canSelect: selecting && page == .library,
//          selectedElements: librarySelection,
//          selectionCapacity: user.importsLeft,
//          elements: library.value?.selected?.images ?? []
//        )
//      }
//      set {
//        librarySelection = newValue.selectedElements
//      }
//    }
//
//    public var libraryAlbums: LibraryAlbums.State {
//      get {
//        .init(
//          canSelect: false,
//          selectedElements: [],
//          selectionCapacity: 0,
//          elements: library.value?.albums ?? []
//        )
//      }
//      set {}
//    }
    
    public var product: Engine.Product?
    
    //public var _paywall: Paywall.State?
    public var paywall: Paywall.State? {
      get {
        if let product = product {
          guard !user.purchased(product) else { return nil }
          return .init(
            user: user,
            product: product,
            initialSelectedPayment: product.acceptedPayments.first
          )
        }
        return nil
//        _paywall.map {
//          .init(
//            user: user,
//            product: $0.product,
//            initialSelectedPayment: $0.initialSelectedPayment
//          )
//        }
      }
//      set {
//        _paywall = newValue
//      }
    }
    
    public init(
      page: Page = .roll,
      user: User,
      selectEnabled: Bool = false,
      library: Usage<Library.State> = .enabled(.empty),
      edit: Edit.State? = nil,
      rollSelection: Set<FilteredImage> = [],
      librarySelection: Set<PhotoLibrary.Image> = [],
      notification: Engine.Notification?,
      fetching: Bool,
      product: Engine.Product?,
      env: SystemEnvironment<Environment>
    ) {
      self.page = page
      self.user = user
      self.selecting = selectEnabled
      self._library = library
      self._edit = edit
      self.rollSelection = rollSelection
      //self.librarySelection = librarySelection
      self.notification = notification
      self.fetching = fetching
      self.product = product
      self._env = EquatableNoop(env)
    }
  }
  
  public enum Action: Equatable {
    //case onDismissEdit
    case setPage(Page)
    case navigateToCamera
    case setSelectEnabled(Bool)
    case image(ImageOption)
    case `import`
    case imported
    case filter(UIImage)
    case filtered(FilteredImage)
    case purchaseCompleted(Set<Purchase>)
    case setNotification(Engine.Notification?)
    case downloadComplete(Result<Bool, EquatableError>)
    case error(EquatableError)
    
    case roll(Roll.Action)
    case library(Library.Action)
//    case libraryImages(LibraryImages.Action)
//    case libraryAlbums(LibraryAlbums.Action)
    case edit(Edit.Action)
    case paywall(Paywall.Action)
  }
  
  public struct Environment {
    public var factory: FilteredImage.Factory
    public var productStore: ProductStore
    public var downloader: MediaDownloader<LocalImage>
    
    public var edit: Edit.Environment {
      .init(
        factory: factory,
        downloader: downloader
      )
    }
    
    public init(
      factory: FilteredImage.Factory,
      productStore: ProductStore,
      downloader: MediaDownloader<LocalImage>
    ) {
      self.factory = factory
      self.productStore = productStore
      self.downloader = downloader
    }
  }
  
  private static var libraryIntermediateReducer: Reducer<Usage<Library.State>, Main.Action, Void> {
    Library.reducer.pullback(
      state: /Usage<Library.State>.enabled,
      action: /Action.library,
      environment: { _ in }
    )
  }
  
  private static let subreducers: Reducer<State, Action, Void> = .combine(
    Roll.reducer().pullback(
      state: \.roll,
      action: /Action.roll,
      environment: { _ in }
    ),
    libraryIntermediateReducer.pullback(
      state: \.library,
      action: /.`self`,
      environment: { _ in }
    ),
    Edit.reducer.optional().pullback(
      state: \.edit,
      action: /Action.edit,
      environment: { _ in }
    )
  )
    
  public static let reducer: Reducer<State, Action, Void> = .combine(
    subreducers,
    .init { state, action, _ in
      switch action {
      case
        let .image(.download(option)),
        let .edit(.image(.download(option))):
        if option != .original, (state.user.importsLeft ?? .max) > 0, !state.user.viewedReviewPrompt {
          SKStoreReviewController.requestReviewInCurrentScene()
          state.user.viewedReviewPrompt = true
        }
      default:
        break
      }
      return .none
    },
    .init { state, action, _ in
      let env = state.env
      
      switch action {
      case let .setSelectEnabled(selectEnabled):
        state.selecting = selectEnabled
        if !selectEnabled {
          state.rollSelection = []
          state.library = state.library.map { library in
            update(library) { $0.selectedImages = [] }
          }
        }
        return .none

      case let .roll(elementId):
        guard !state.selecting else { return .none }
        state.edit = .init(
          elements: state.user.images,
          presets: state.user.presets,
          currentElementId: elementId,
          editSession: nil,
          notification: nil,
          isSaving: false,
          env: env.map(\.edit)
        )
        return .none
        
      case let .library(.selectAlbum(elementId)):
        state.library = state.library.map {
          $0.select(id: elementId)
        }
        return .none
        
      case .edit(.onDismiss):
        state.edit = nil
        return .none
        
      case let .setPage(page):
        state.page = page
        return Effect(value: .setSelectEnabled(false))
        
      case .image(.delete):
        state.rollSelection.forEach { state.user.images.remove(id: $0.id) }
        state.selecting = false
        state.rollSelection = []
        return .none
        
      case .import:
        guard let selectedImages = state.library.value?.selectedImages else { return .none }
        return .concatenate(
          Effect(value: .setPage(.roll)),
          Publishers.Sequence(sequence: selectedImages.sorted(by: { $0.index < $1.index }))
            .receive(on: env.storageScheduler)
            // .delay(for: 3, scheduler: env.storageScheduler) // test
            .flatMap { (photoLibraryImage: PhotoLibrary.Image) in
              photoLibraryImage.photoWithSize(.full)
                .tryMap { try env.factory.create($0, .init(originDate: photoLibraryImage.date)) }
                .receive(on: env.mainScheduler)
                .flatMap { filteredImage -> AnyPublisher<Action, Never> in
                  Publishers.Sequence(sequence: [Action.filtered(filteredImage), Action.imported])
                    .eraseToAnyPublisher()
                }
                .catch { Just(Action.error($0.equatable)) }
            }
            .eraseToEffect()
        )

      case .imported:
        state.user.importsCount += 1
        return .none
        
      case let .filter(image):
        return Just(image)
          .receive(on: env.storageScheduler)
          .tryMap { try env.factory.create($0, .init(originDate: env.date())) }
          .receive(on: env.mainScheduler)
          .map(Action.filtered)
          .catch { Just(Action.error($0.equatable)) }
          .eraseToEffect()
        
      case let .filtered(filteredImage):
        state.user.images.append(filteredImage)
        return .none
        
      case let .paywall(.purchase(with: payment)):
        guard let product = state.paywall?.product else { return .none }
        return env.productStore.purchase(product, payment)
          .map { Set<Purchase>([$0]) }
          .receive(on: env.mainScheduler)
          .map(Action.purchaseCompleted)
          .catch { Just(Action.error($0.equatable)) }
          .eraseToEffect()
      
      case .paywall(.restorePurchases):
        return env.productStore.restorePurchases()
          .receive(on: env.mainScheduler)
          .map(Action.purchaseCompleted)
          .catch { Just(Action.error($0.equatable)) }
          .eraseToEffect()
        
      case .edit(.image(.delete)):
        if state.edit?.elements.count == 0 { state.edit = nil }
        return .none

      case let .image(.download(option)):
        return env.download(state.rollSelection.flatMap { filteredImage in option.keyPaths.map { filteredImage[keyPath: $0] }})
          .catchToEffect(Action.downloadComplete)
        
      case let .edit(.image(.download(option))):
        return env.download(option.keyPaths.map { state.edit!.currentElement[keyPath: $0] })
          .catchToEffect { Action.edit(.downloadComplete($0)) }
          
      case let .downloadComplete(.failure(error)):
        print(error)
        state.notification = .downloadFailure
        return .none

      case .downloadComplete(.success):
        state.notification = .downloadSuccess
        return .none
        
      case let .setNotification(notification):
        state.notification = notification
        return .none
        
      case let .error(error):
        print(error)
        return .none
        
      case .edit, .library, .image, .navigateToCamera, .purchaseCompleted:
        return .none
      }
    }
  )
  
  public enum Page: Equatable {
    case roll
    case library
  }
  
  public typealias Store = ComposableArchitecture.Store<State, Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<State, Action>
}

extension SystemEnvironment where Environment == Main.Environment {
  func download(_ localImages: [LocalImage]) -> AnyPublisher<Bool, EquatableError> {
    return Publishers.Sequence(sequence: localImages)
      .flatMap { self.downloader.download($0) }
      .receive(on: mainScheduler)
      .mapError { $0.equatable }
      .map { true }
      .collect()
      .map { results in results.reduce(true, { $0 && $1 }) }
      .eraseToAnyPublisher()
  }
}

extension SKStoreReviewController {
  public static func requestReviewInCurrentScene() {
    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
      DispatchQueue.main.async {
        requestReview(in: scene)
      }
    }
  }
}


