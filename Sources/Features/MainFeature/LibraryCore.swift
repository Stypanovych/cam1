import ComposableArchitecture
import Engine

public enum Library: Equatable {
  public struct State: Equatable {
    public var albums: IdentifiedArrayOf<PhotoLibrary.Album>
    public var canSelect: Bool
    public var selectionCapacity: Int?
    public var selectedImages: Set<PhotoLibrary.Image>
    public var selectedAlbum: SelectedAlbum?
    public var page: Page { selectedAlbum == nil ? .albums : .images }
    
    public var libraryImages: LibraryImages.State {
      get {
        .init(
          canSelect: canSelect,
          selectedElements: selectedImages,
          selectionCapacity: selectionCapacity,
          elements: selectedAlbum?.images ?? []
        )
      }
      set {
        selectedImages = newValue.selectedElements
      }
    }
    
    public init(
      albums: IdentifiedArrayOf<PhotoLibrary.Album>,
      canSelect: Bool,
      selectionCapacity: Int?,
      selectedImages: Set<PhotoLibrary.Image>,
      selectedAlbum: SelectedAlbum?
    ) {
      self.albums = albums
      self.canSelect = canSelect
      self.selectionCapacity = selectionCapacity
      self.selectedImages = selectedImages
      self.selectedAlbum = selectedAlbum
    }
    
    public struct SelectedAlbum: Equatable {
      public var album: PhotoLibrary.Album
      public var images: IdentifiedArrayOf<PhotoLibrary.Image>
    }
    
    public func select(id: PhotoLibrary.Album.ID) -> Self {
      update(self) {
        $0.selectedAlbum = albums[id: id].map {
          .init(album: $0, images: IdentifiedArrayOf(uniqueElements: $0.images()))
        }
      }
    }
    
    public static var empty: Self {
      .init(
        albums: [],
        canSelect: false,
        selectionCapacity: 0,
        selectedImages: [],
        selectedAlbum: nil
      )
    }
    
    public static func unselected(albums: IdentifiedArrayOf<PhotoLibrary.Album>) -> Self {
      update(.empty) {
        $0.albums = albums
      }
    }
  }
  
  public enum Action: Equatable {
    case showAlbums
    case libraryImages(LibraryImages.Action)
    case selectAlbum(PhotoLibrary.Album.ID)
  }
  
  public static let reducer: Reducer<State, Action, Void> = .combine(
    LibraryImages.reducer().pullback(
      state: \.libraryImages,
      action: /Action.libraryImages,
      environment: { _ in }
    ),
    .init { state, action, _ in
      switch action {
      case let .selectAlbum(albumId):
        state = state.select(id: albumId)
        return .none
        
      case .showAlbums:
        state.selectedAlbum = nil
        return .none
        
      case .libraryImages:
        return .none
      }
    }
  )
  
  public enum Page: Equatable {
    case albums
    case images
  }
  
  public typealias Store = ComposableArchitecture.Store<Library.State, Library.Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<Library.State, Library.Action>
}
