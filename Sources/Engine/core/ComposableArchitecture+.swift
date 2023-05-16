import ComposableArchitecture
import DazeFoundation
import CoreImage

public typealias Substate = EquatableNoop
public typealias OptionalSubstate = OptionalEquatableNoop

extension Reducer {
  func resending<Value>(
    _ extract: @escaping (Action) -> Value?,
    to embed: @escaping (Value) -> Action
  ) -> Self {
    .combine(
      self,
      .init { _, action, _ in
        if let value = extract(action) {
          return Effect(value: embed(value))
        } else {
          return .none
        }
      }
    )
  }

  func resending<Value>(
    _ `case`: CasePath<Action, Value>,
    to other: CasePath<Action, Value>
  ) -> Self {
    resending(`case`.extract(from:), to: other.embed(_:))
  }

  func resending<Value>(
    _ `case`: CasePath<Action, Value>,
    to other: @escaping (Value) -> Action
  ) -> Self {
    resending(`case`.extract(from:), to: other)
  }

  func resending<Value>(
    _ extract: @escaping (Action) -> Value?,
    to other: CasePath<Action, Value>
  ) -> Self {
    resending(extract, to: other.embed(_:))
  }
}

/*
 parentReducer
   .resending(/ParentAction.fooClient, to: /ParentAction.child1 .. Child1Action.fooClient)
   .resending(/ParentAction.fooClient, to: /ParentAction.child2 .. Child2Action.fooClient)
   .resending(/ParentAction.fooClient, to: { value in .boolAction(value > 5) })
 */

//extension Store {
//  public func scope<LocalState: Equatable, LocalAction>(
//    state toLocalState: @escaping (State) -> LocalState,
//    action fromLocalAction: @escaping (LocalAction) -> Action
//  ) -> Store<LocalState, LocalAction> {
//    let localStore = Store<LocalState, LocalAction>(
//      initialState: toLocalState(self.state.value),
//      reducer: { localState, localAction in
//        self.send(fromLocalAction(localAction))
//        localState = toLocalState(self.state.value)
//        return .none
//      }
//    )
//    localStore.parentCancellable = self.state
//      .sink { [weak localStore] newValue in
//        print("Optimized scoping")
//          let newState = toLocalState(newValue)
//          guard newState != localStore?.state.value else {
//              print("Duplicate")
//              return
//          }
//        localStore?.state.value = newState
//    }
//    return localStore
//  }
//}
extension Store where State: Equatable {
  public func scopeDeduping<LocalState: Equatable, LocalAction>(
    state toLocalState: @escaping (State) -> LocalState,
    action fromLocalAction: @escaping (LocalAction) -> Action
  ) -> Store<LocalState, LocalAction> {
    var previous: (state: State, localState: LocalState)?
    return scope(
      state: { state -> LocalState in
        if let previous = previous, state == previous.state {
          return previous.localState
        }
        previous = (state: state, localState: toLocalState(state))
        return previous!.localState
      },
      action: fromLocalAction
    )
  }
}

extension ViewStore {
  public static func noopDeduping(_ store: Store<State, Action>) -> ViewStore {
    return .init(store, removeDuplicates: { _, _ in false })
  }
}

@dynamicMemberLookup
public struct BaseState<State> {
  public var user: User
  public var state: State
  
  public init(
    user: User,
    state: State
  ) {
    self.user = user
    self.state = state
  }

  subscript<Substate>(
    dynamicMember keyPath: WritableKeyPath<State, Substate>
  ) -> Substate {
    get { self.state[keyPath: keyPath] }
    set { self.state[keyPath: keyPath] = newValue }
  }
}

@dynamicMemberLookup
public struct SystemEnvironment<Environment> {
  public var filter: DazeFilter
  public var storageScheduler: AnySchedulerOf<DispatchQueue>
  public var mainScheduler: AnySchedulerOf<DispatchQueue>
  public var cameraScheduler: AnySchedulerOf<DispatchQueue>
  public var renderScheduler: AnySchedulerOf<DispatchQueue>
  public var ioScheduler: AnySchedulerOf<DispatchQueue>
  public var renderContext: CIContext
  public var date: () -> Date
  public var uuid: () -> UUID
  
  public let environment: Environment

  public subscript<Dependency>(
    dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
  ) -> Dependency {
    get { self.environment[keyPath: keyPath] }
    //set { self.environment[keyPath: keyPath] = newValue }
  }

  /// Creates a live system environment with the wrapped environment provided.
  ///
  /// - Parameter environment: An environment to be wrapped in the system environment.
  /// - Returns: A new system environment.
  public static func live(environment: Environment) -> Self {
    let storageScheduler = DispatchQueue.background(.serial("com.DAZE35.storage"), .userInitiated).eraseToAnyScheduler()
    let cameraScheduler = DispatchQueue.background(.serial("com.DAZE35.camera"), .userInitiated).eraseToAnyScheduler()
    let renderScheduler = DispatchQueue.background(.serial("com.DAZE35.render"), .userInteractive).eraseToAnyScheduler()
    let ioScheduler = DispatchQueue.background(.concurrent, .userInteractive).eraseToAnyScheduler()
    return .init(
      filter: Engine.filter,
      storageScheduler: storageScheduler,
      mainScheduler: .main,
      cameraScheduler: cameraScheduler,
      renderScheduler: renderScheduler,
      ioScheduler: ioScheduler,
      renderContext: Renderer.lowQuality.context,
      date: Date.init,
      uuid: UUID.init,
      environment: environment
    )
  }

  /// Transforms the underlying wrapped environment.
  public func map<NewEnvironment>(
    _ transform: @escaping (Environment) -> NewEnvironment
  ) -> SystemEnvironment<NewEnvironment> {
    .init(
      filter: self.filter,
      storageScheduler: self.storageScheduler,
      mainScheduler: self.mainScheduler,
      cameraScheduler: self.cameraScheduler,
      renderScheduler: self.renderScheduler,
      ioScheduler: self.ioScheduler,
      renderContext: self.renderContext,
      date: self.date,
      uuid: self.uuid,
      environment: transform(self.environment)
    )
  }
}

#if DEBUG
public extension SystemEnvironment {
  static func mock(environment: Environment) -> Self {
    return .live(environment: environment)
  }
}
#endif

//extension Reducer where State == Root.State, Environment == Root.Environment, Action == Root.Action {
//  func persistSettings() -> Reducer {
//    return .init { state, action, environment in
//      let previousState = state
//
//      var effect = self.run(&state, action, environment)
//
//      if state.settings != previousState.settings {
//        effect = .merge(effect, Effect(value: .persistSettings(state.settings)).debounce(id: SettingsPersistanceIdentifier(), for: 1, scheduler: environment.mainQueue))
//      }
//      if state.user != previousState.user {
//        effect = .merge(effect, Effect(value: .persistUser(state.user)).debounce(id: UserPersistanceIdentifier(), for: 1, scheduler: environment.mainQueue))
//      }
//
//      return effect
//    }
//  }
//}

