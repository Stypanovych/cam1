import Capture
import Combine
import ComposableArchitecture
import UIKit
import DazeFoundation
import Engine
//import AVKit

public enum Capture {
  public struct State: Equatable {
    public var preview: Usage<CALayer>?
    public var cameraSettings: Camera.Settings
    
    @EquatableNoop
    public var cameraInterface: Camera.Interface?
    
    @EquatableNoop
    public var env: SystemEnvironment<Environment>
    
    public init(
      cameraSettings: Camera.Settings,
      env: SystemEnvironment<Environment>
    ) {
      self.cameraSettings = cameraSettings
      self._env = EquatableNoop(env)
      self._cameraInterface = EquatableNoop(nil)
    }
  }
  
  public enum Action: Equatable {
    case setup
    case setupComplete(Result<EquatableNoop<Camera.Interface>, EquatableError>)
    case capturePhoto(flash: Bool)
    case receivedPhoto(UIImage)
    case toggleOrientation
    case navigateToMain
  }
  
  public struct Environment {
    public var camera: Camera
    
    public init(camera: Camera) {
      self.camera = camera
    }
  }
  
  public static let reducer = Reducer<State, Action, Void> { state, action, _ in
    let env = state.env
    
    switch action {
    case .setup:
      return env.camera.turnOn(state.cameraSettings, env.cameraScheduler)
        .map(EquatableNoop.init)
        .mapError { $0.equatable }
        .catchToEffect(Action.setupComplete)
      
    case let .setupComplete(result):
      guard let interface = result.value?.wrappedValue else {
        state.preview = .disabled
        return .none
      }
      state.cameraInterface = interface
      state.preview = .enabled(interface.preview)
      return .none
      
    case let .receivedPhoto(image):
      return .none
      
    case let .capturePhoto(flash: flash):
      guard let cameraInterface = state.cameraInterface else { return .none }
      state.cameraSettings = cameraInterface.adjustFlash(flash ? .on : .off)
      return cameraInterface.capture()
        .receive(on: env.mainScheduler)
        .map { .receivedPhoto($0.photo) }
        .eraseToEffect()
      
    case .toggleOrientation:
      guard let cameraInterface = state.cameraInterface else { return .none }
      let newOrientation = (state.cameraSettings.orientation == .front) ? Camera.Settings.Orientation.back : .front
      state.cameraSettings = cameraInterface.adjustOrientation(newOrientation)
      return .none
      
    case .navigateToMain:
      return .none
    }
  }
  
  public typealias Store = ComposableArchitecture.Store<State, Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<State, Action>
}

//extension Capture.State: Equatable {
//  public static func == (lhs: Capture.State, rhs: Capture.State) -> Bool {
//    lhs.orientation == lhs.orientation &&
//    lhs.captureSession == rhs.captureSession &&
//    lhs.capturer == rhs.capturer
//  }
//}
//
//extension PhotoCapturer {
//  func capturePhoto() -> Future<PhotoData, Error> {
//    return Future { promise in
//      capturePhoto { result in
//        promise(result)
//      }
//    }
//  }
//}



//enum Navigation {
//  struct State: Equatable {
//    let pages: [Page.State]
//  }
//  enum Action: Equatable {
//    case prev
//    case next
//    case page(Page.Action)
//  }
//  struct Environment {}
//
//  static let pageReducer: [Reducer<Page.State, Page.Action, Void>] = []
//  static let pageReducers: [Reducer<Page.State, Page.Action, Void>] = []
//  static let reducer = Reducer<State, Action, Environment>.combine(
//    pageReducer.for
//    .init { state, action, env in
//
//    }
//  )
//
//  func test() {
//    Reducer<Page.State, Page.Action, Void>().forEach(
//      state: ,
//      action:
//      environment: )
//  }
//}
//
//enum Page {
//  enum State: Equatable {}
//  enum Action {
//    case completed
//  }
//}
//
//enum PageA {
//  struct State: Equatable {}
//  enum Action: Equatable {
//    case page(Page.Action)
//    case someOtherAction
//  }
//  struct Environment {}
//
//  static let reducer = Reducer<State, Action, Environment> { state, action, env in
//
//  }
//}
//
//enum PageB {
//  struct State: Equatable {}
//  enum Action: Equatable {
//    case page(Page.Action)
//    case someOtherAction
//  }
//  struct Environment {}
//
//  static let reducer = Reducer<State, Action, Environment> { state, action, env in
//
//  }
//}
