import Capture
import Combine
import ComposableArchitecture
import CoreImage
import UIKit
import DazeFoundation
import Engine
import Photos
import SwiftUI

public enum EditPanel: String, Hashable {
  case filter
  case leak
  case glow
  case grain
  case blur
  case chroma
  case date
  case dust
  case vignette
}

public enum EditSession {
  public struct State: Equatable {
    public let metadata: FilteredImage.Metadata
    @BindableState public var filterParameters: FilteredImage.Parameters
    @OptionalEquatableNoop public var parameterResources: InMemoryResources?
    public let panels: [EditPanel] = [.filter, .chroma, .leak, .glow, .grain, .blur, .date, .dust, .vignette]
    @BindableState public var tool: Tool
    
    public var customPreset: Preset
    //private let systemPresets: [Preset] = [.system1]
    public var userPresets: [Preset]
    public var presets: [Preset] { [customPreset] + userPresets }
    
    public let originalImage: CIImage
    public var filteredImage: CIImage?
    public var imageToRender: CIImage?
    public var resizedImage: CIImage? {
      renderSize.map { renderSize in
        originalImage.filter {
          //passthrough()
          size(.fitting(area: renderSize))
        }
      }
    }
    
    public var renderSize: CGFloat?
    
    @BindableState public var currentPanel: EditPanel = .filter
    @BindableState public var currentPreset: Preset
    
    @EquatableNoop
    public var env: SystemEnvironment<Environment>
    
    public init(
      userPresets: IdentifiedArrayOf<User.Preset>,
      metadata: FilteredImage.Metadata,
      filterParameters: FilteredImage.Parameters,
      parameterResources: InMemoryResources?,
      tool: Tool,
      originalImage: CIImage,
      filteredImage: CIImage?,
      imageToRender: CIImage?,
      currentPanel: EditPanel,
      currentPreset: Preset,
      renderSize: CGFloat?,
      env: SystemEnvironment<Environment>
    ) {
      self.userPresets = userPresets.map { .user($0) }
      self.metadata = metadata
      self.filterParameters = filterParameters
      self._parameterResources = OptionalEquatableNoop(parameterResources)
      self.tool = tool
      self.originalImage = originalImage
      self.filteredImage = filteredImage
      self.imageToRender = imageToRender
      self.customPreset = .custom(filterParameters)
      self.currentPreset = currentPreset
      self.currentPanel = currentPanel
      self.renderSize = renderSize
      self._env = EquatableNoop(env)
    }
    
    public enum Tool {
      case effects
      case presets
      
      var name: String {
        switch self {
        case .effects: return "EFFECTS"
        case .presets: return "PRESETS"
        }
      }
      
      func background(_ theme: Theme) -> Color {
        switch self {
        case .effects: return theme.dark.swiftui
        case .presets: return theme.red.swiftui
        }
      }
      
      var toggled: Self {
        switch self {
        case .effects: return .presets
        case .presets: return .effects
        }
      }
    }
  }
  
  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case render
    case refresh
    case filter(FilteredImage.Parameters, InMemoryResources)
    case renderSize(CGFloat)

    case showOriginal
    case showFiltered
  }
  
  public struct Environment {}
  
  // TODO: state is copied or evaluated at execution?
  public static let reducer = Reducer<State, Action, Void> { state, action, _ in
    let env = state.env

    struct ThrottleToken: Hashable {}
    struct CancelToken: Hashable {}
    
    switch action {
    case .render:
      return Just((state.filterParameters, state.parameterResources))
        .receive(on: env.renderScheduler)
        .map { parameters, resources in
          let newResources = resources.map { parameters.resources(diffing: $0) } ?? parameters.resources()
          return (parameters, newResources)
        }
        .receive(on: env.mainScheduler)
        .map { Action.filter($0, $1) }
        .eraseToEffect()
        .cancellable(id: CancelToken(), cancelInFlight: true)
      
    case let .filter(parameters, resources):
      guard let resizedImage = state.resizedImage else { return .none }
      state.filteredImage = env.filter(resizedImage, state.metadata, parameters, resources)
      state.imageToRender = state.filteredImage
      state.parameterResources = resources
      return .none
      
    // the picker gives us back a stale preset. we need to deal with ids
    // preset is set, then in the process of moving to that preset we create an unequal filter parameters which triggers custom
    case
        .binding(\.$filterParameters),
        .binding(\.$filterParameters.lookup),
        .binding(\.$filterParameters.lightLeak),
        .binding(\.$filterParameters.stampFont):
      if state.currentPreset.parameters != state.filterParameters {
        state.customPreset = .custom(state.filterParameters)
      }
      return Effect(value: .set(\.$currentPreset, state.customPreset))
      
    case .binding(\.$currentPreset):
      state.filterParameters = state.currentPreset.parameters
      return Effect(value: .refresh)
      
    case .refresh:
      return .concatenate(
        Effect.cancel(id: CancelToken()),
        Effect(value: .render)
          .throttle(
            id: ThrottleToken(),
            for: 0.05,
            scheduler: env.mainScheduler,
            latest: true
          )
      )
      
    case .showOriginal:
      state.imageToRender = state.resizedImage
      return .none
      
    case .showFiltered:
      state.imageToRender = state.filteredImage
      return .none
      
    case let .renderSize(size):
      state.renderSize = size
      return .none
      
    case .binding:
      return .none
    }
  }
    .binding()
  
  public typealias Store = ComposableArchitecture.Store<State, Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<State, Action>
}
