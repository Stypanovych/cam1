import UIKit
import ComposableArchitecture
import Combine
import Engine
import SwiftUI
import DazeFoundation

public struct EditControlsView: View {
  public typealias ViewState = Edit.State
  public typealias Action = Edit.Action

  public typealias Store = ComposableArchitecture.Store<ViewState, Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<ViewState, Action>
  
  public let store: Store
  public let addPresetAction: () -> Void

  @State private var renderSize: CGFloat = 0
  
  @EnvironmentObject private var theme: Theme
  
  public init(
    store: Store,
    addPresetAction: @escaping () -> Void
  ) {
    self.store = store
    self.addPresetAction = addPresetAction
  }

  @Namespace private var namespace
  
  public var body: some View {
    WithViewStore(store) { viewStore in
      VStack(spacing: 0) {
        ZStack {
          VStack(spacing: 0) {
            let editCategoryViewVisible = viewStore.state.editSession?.tool == .effects
            EditCollectionView(store: store)
              .animation(
                editCategoryViewVisible ? .dazecamDefault : .dazecamDefault.delay(Animation.dazecam),
                value: viewStore.state.editSession?.tool
              )
            let editSessionStore = store.scope(
              state: \.editSession,
              action: Edit.Action.editSession
            )
            VStack {
              if editCategoryViewVisible {
                IfLetStore(
                  editSessionStore,
                  then: { editSessionStore in
                    WithViewStore(editSessionStore) { editSessionViewStore in
                      EditCategoryView(store: editSessionStore)
                        .transition(.delayedFade)
                    }
                  },
                  else: {
                    Color.clear
                  }
                )
              } else {
                Color.clear
              }
            }
            .frame(height: editCategoryViewVisible ? theme.barHeight * 3 : 0)
            .background(
              theme.dark.swiftui
                .shadow(color: .black.opacity(0.35), radius: theme.shadow.radius)
                .animation(
                  editCategoryViewVisible ? .dazecamDefault : .dazecamDefault.delay(Animation.dazecam),
                  value: editCategoryViewVisible
                )
            )
          }
          VStack {
            Spacer()
            if let notification = viewStore.notification {
              NotificationView(notification: notification)
                .transition(.move(edge: .bottom))
            }
          }
          .animation(.dazecamDefault, value: viewStore.notification == nil)
        }
        EditBar(
          store: store,
          editAction: { viewStore.send(.edit(.start)) },
          addPresetAction: addPresetAction
        )
      }
    }
  }
}

extension AnyTransition {
  static var delayedFade: Self {
    .asymmetric(
      insertion: .opacity.animation(.dazecamDefault.delay(Animation.dazecam)),
      removal: .opacity.animation(.dazecamDefault)
    )
  }
}
