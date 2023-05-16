import Capture
import Combine
import ComposableArchitecture
import CoreImage
import UIKit
import DazeFoundation
import Engine
import Photos

public enum Edit {
  public enum Page: Equatable {
    case edit
  }
  
  public struct State: Equatable {
    public var elements: IdentifiedArrayOf<FilteredImage>
    public var presets: IdentifiedArrayOf<User.Preset>

    public var currentElementId: FilteredImage.ID
    public var currentElement: FilteredImage { elements[id: currentElementId]! }

    public var notification: Engine.Notification?
    public let downloadOptions = ImageOption.Download.all
    
    public var isSaving: Bool

    //@OptionalSubstate
    public var _editSession: EditSession.State?
    public var editSession: EditSession.State? {
      get {
        _editSession.map {
          .init(
            userPresets: presets,
            metadata: $0.metadata,
            filterParameters: $0.filterParameters,
            parameterResources: $0.parameterResources,
            tool: $0.tool,
            originalImage: $0.originalImage,
            filteredImage: $0.filteredImage,
            imageToRender: $0.imageToRender,
            currentPanel: $0.currentPanel,
            currentPreset: $0.currentPreset,
            renderSize: $0.renderSize,
            env: $0.env
          )
        }
      }
      set {
        _editSession = newValue
      }
    }
    
    @EquatableNoop
    public var env: SystemEnvironment<Environment>

    public init(
      elements: IdentifiedArrayOf<FilteredImage>,
      presets: IdentifiedArrayOf<User.Preset>,
      currentElementId: FilteredImage.ID,
      editSession: EditSession.State?,
      notification: Engine.Notification?,
      isSaving: Bool,
      env: SystemEnvironment<Environment>
    ) {
      self.elements = elements
      self.presets = presets
      self.currentElementId = currentElementId
      self.notification = notification
      self.isSaving = isSaving
      self._env = EquatableNoop(env)
      self._editSession = editSession
    }
  }

  public enum Action: Equatable {
    case onDismiss
    case image(ImageOption)
    case edit(EditOption)
    case scroll(to: FilteredImage.ID)
    case newPreset(_ name: String)
    
    case setNotification(Engine.Notification?)
    
    case editSession(EditSession.Action)
    case downloadComplete(Result<Bool, EquatableError>)
    case saveComplete(Result<FilteredImage, EquatableError>)
    case retry
    
    public enum EditOption: Hashable {
      case start
      case save
      case cancel
    }
  }
  
  public struct Environment {
    public var factory: FilteredImage.Factory
    public var downloader: MediaDownloader<LocalImage>
    
    var editSession: EditSession.Environment { .init() }
    
    public init(
      factory: FilteredImage.Factory,
      downloader: MediaDownloader<LocalImage>
    ) {
      self.factory = factory
      self.downloader = downloader
    }
  }
  
  public static let reducer = Reducer<State, Action, Void>.combine(
    EditSession.reducer.optional().pullback(
      state: \.editSession,
      action: /Action.editSession,
      environment: { _ in }
    ),
    .init { state, action, _ in
      struct NotificationCancelToken: Hashable {}
      
      let env = state.env
      
      switch action {
      case .edit(.start):
        let ciimage = CIImage(contentsOf: state.currentElement.originalImagePath.url)!
//          .filter {
//          size(.fitting(area: state.renderSize))
//        }
        state.editSession = .init(
          userPresets: state.presets,
          metadata: state.currentElement.metadata,
          filterParameters: state.currentElement.parameters,
          parameterResources: nil,
          tool: .effects,
          originalImage: ciimage,
          filteredImage: nil,
          imageToRender: nil,
          currentPanel: .filter,
          currentPreset: state.currentElement.preset.map(Preset.user) ?? .custom(state.currentElement.parameters),
          renderSize: nil,
          env: env.map(\.editSession)
        )
        return .none
        
      case let .scroll(to: elementId):
        //print(state.elements.index(id: elementId))
        state.currentElementId = elementId
        return .none
        
      case .edit(.cancel):
        // render, save
        state.editSession = nil
        return .none

      case .edit(.save):
        guard let editSession = state.editSession else { return .none }
        state.isSaving = true
        let filterParameters = editSession.filterParameters
        let filteredImage = update(state.currentElement) { $0.preset = editSession.currentPreset.userPreset }
        return Future.deferred { (promise: (Result<FilteredImage, Error>) -> Void) in
          let result = Result(catching: { try env.factory.update(filteredImage, filterParameters) })
          promise(result)
        }
          .mapError { $0.equatable } // won't compile as \.equtable
          .subscribe(on: env.renderScheduler)
          .receive(on: env.mainScheduler)
          .catchToEffect(Action.saveComplete)
        
      case let .saveComplete(.success(filteredImage)):
        guard state.currentElementId == filteredImage.id
        else { return Effect(value: .retry) }
        state.elements[id: state.currentElementId] = filteredImage // current element is different from saved element
        state.editSession = nil
        state.isSaving = false
        return .none

      case let .saveComplete(.failure(error)):
        //state.notification = .saveFailure
        state.isSaving = false
        return Effect(value: .setNotification(.saveFailure))
        
      case .retry:
        state.isSaving = false
        return Effect(value: .setNotification(.tryAgain))
        
      case .image(.delete):
        let index = state.elements.index(id: state.currentElementId)!
        state.elements.remove(id: state.currentElementId)
        guard !state.elements.isEmpty else { return .none }
        let nextIndex = (index - 1).clamped(by: 0...(state.elements.count - 1))
        state.currentElementId = state.elements[nextIndex].id
        return .none
        
      case let .downloadComplete(.failure(error)):
        print(error)
        //state.notification = .downloadFailure
        return Effect(value: .setNotification(.downloadFailure))
        
      case .downloadComplete(.success):
        //state.notification = .downloadSuccess
        return Effect(value: .setNotification(.downloadSuccess))
        
      case let .setNotification(notification):
        state.notification = notification
        return .concatenate(
          .cancel(id: NotificationCancelToken()),
          Effect(value: Action.setNotification(nil))
            .delay(for: 3, scheduler: env.mainScheduler)
            .eraseToEffect()
            .cancellable(id: NotificationCancelToken(), cancelInFlight: true)
        )
        
      case let .newPreset(name):
        guard case let .custom(parameters) = state.editSession?.currentPreset else { return .none }
        let newUserPreset = User.Preset(
          id: .init(),
          name: name,
          creationDate: env.date(),
          parameters: parameters
        )
        state.presets.insert(newUserPreset, at: 0)
        state.editSession?.currentPreset = .user(newUserPreset)
        return .none
        
      case .onDismiss, .editSession, .image:
        return .none
      }
    }
  )
  
  public typealias Store = ComposableArchitecture.Store<State, Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<State, Action>
}

//extension Edit.State: Equatable {
//  public static func == (lhs: Self, rhs: Self) -> Bool {
//    return lhs.elements == rhs.elements &&
//      lhs.currentIndex == rhs.currentIndex &&
//      lhs.currentElement == rhs.currentElement &&
//      lhs._editSession == rhs._editSession
//  }
//}

#if DEBUG
//extension Edit.Environment {
//  static func mock() -> Self {
//    return .init(
//      factory: .persistedToDisk(filter: filter),
//      renderQueue: renderQueue,
//      filter: filter,
//      renderContext: Renderer.lowQuality.context,
//      downloader: .mock(success: false)
//    )
//  }
//}
#endif
