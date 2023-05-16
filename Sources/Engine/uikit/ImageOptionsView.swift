import ComposableArchitecture
import SwiftUI

public struct ImageOptionsViewState: Equatable {
  let optionsVisible: Bool
  let downloadOptions: [ImageOption.Download]
  
  public init(
    optionsVisible: Bool,
    downloadOptions: [ImageOption.Download]
  ) {
    self.optionsVisible = optionsVisible
    self.downloadOptions = downloadOptions
  }
}
public typealias ImageOptionsAction = ImageOption

public struct ImageOptionsView<Content: View>: View {
  public typealias Store = ComposableArchitecture.Store<ImageOptionsViewState, ImageOptionsAction>
  public typealias ViewStore = ComposableArchitecture.ViewStore<ImageOptionsViewState, ImageOptionsAction>
  
  public let store: Store
  public let content: () -> Content
  @State private var prompt: Prompt? = nil
  
  @EnvironmentObject private var theme: Theme
  
  private enum Prompt {
    case download
    case delete
  }
  
  public init(
    store: Store,
    _ content: @escaping () -> Content
  ) {
    self.store = store
    self.content = content
  }
  
  @ViewBuilder
  func edit(_ viewStore: ViewStore) ->  some View {
    content()
    Spacer()
    if viewStore.optionsVisible {
      DazeButton("DOWNLOAD") { prompt = .download }
      Spacer()
      DazeButton("DELETE") { prompt = .delete }
    }
  }
  
  @ViewBuilder
  func download(_ viewStore: ViewStore) -> some View {
    DazeButton(image: .dazecam.back) { prompt = nil  }
      .frame(height: 13)
    Margin.horizontal(2)
    HStack {
      let downloadOptions = viewStore.state.downloadOptions
      ForEach(downloadOptions, id: \.self) { option in
        DazeButton(option.text.uppercased()) {
          viewStore.send(.download(option))
          prompt = nil
        }
        if option != downloadOptions.last { Spacer() }
      }
    }
  }
  
  @ViewBuilder
  func delete(_ viewStore: ViewStore) -> some View {
    Spacer()
    Text("SURE?")
      .font(theme.main.large.heavy.uiFont.swiftui)
      .foregroundColor(theme.dark.swiftui)
    Margin.horizontal(2)
    DazeButton("YES", color: theme.red.swiftui) {
      viewStore.send(.delete)
      prompt = nil
    }
    Margin.horizontal(2)
    DazeButton("NO") { prompt = nil }
  }
  
  public var body: some View {
    WithViewStore(store) { viewStore in
      HStack {
        switch prompt {
        case nil: edit(viewStore)
        case .delete: delete(viewStore)
        case .download: download(viewStore)
        }
      }
    }
  }
}
