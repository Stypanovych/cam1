import Combine
import Engine
import SwiftUI
import UIKit
import Resources
import ImageProcessor
import ComposableArchitecture

struct Named<T> {
  let value: T
  let name: String
}

extension Named: Equatable where T: Equatable {}
extension Named: Hashable where T: Hashable {}

struct FilterPickerView: UIViewRepresentable {
  private let store: EditSession.Store
  private let viewStore: EditSession.ViewStore

  init(store: EditSession.Store, viewStore: EditSession.ViewStore) {
    self.store = store
    self.viewStore = viewStore
  }
  
  func makeUIView(context: Context) -> Engine.Picker<Named<Resources.Lut>, TitledImageView> {
    return Engine.Picker<Named<Resources.Lut>, TitledImageView>(
      store: store.scope(
        state: { state in
          .init(
            elements: filters,
            currentElement: filters.first(where: { state.filterParameters.lookup == $0.value.resource }) ?? self.filters[0]
          )
        },
        action: { .set(\.$filterParameters.lookup, $0.value.resource) }
      ),
      map: { lut in
        .configuration(
          title: lut.name,
          { filterThumbnail(resource: lut.value.resource) },
          queue: uiBackgroundQueue
        )
      },
      size: 60,
      spacing: 20
    ) ~~ { $0.collection.backgroundColor = .dazecam.dark }
  }

  func updateUIView(_ uiView: Engine.Picker<Named<Resources.Lut>, TitledImageView>, context: Context) { }
  
  let filters: [Named<Resources.Lut>] = [
    .init(value: Resources.Lut.faded, name: "palm"),
    .init(value: Resources.Lut.jtree, name: "joshua tree"),
    .init(value: Resources.Lut.disposable4, name: "dunes"),
    //.init(value: Resources.Lut.disposable5, name: "joshua tree"),
    //.init(value: Resources.Lut.greenShadows, name: "aurora"),
    .init(value: Resources.Lut.pastel4, name: "mirage"),
    .init(value: Resources.Lut.hybrid1, name: "oasis"),
    .init(value: Resources.Lut.disposable17, name: "dawn"),
    .init(value: Resources.Lut.disposable18, name: "dusk"),
  ]
  
  private func filterThumbnail(resource: Resource) -> UIImage {
    let data = try? viewStore.originalImage
      .filter { image in
        lut(CIImage(contentsOf: resource.url)!, intensity: 1.0)
        size(.fillingAspect(.init(width: 100, height: 100)))
        ImageProcessor.position(.center(in: image.extent))
      }
      .render(compression: 1.0, renderer: .thumbnailQuality)
    return data.map(UIImage.init(data:))! ?? UIImage() // TODO
  }
}

struct LeakPickerView: UIViewRepresentable {
  private let store: EditSession.Store
  private let viewStore: EditSession.ViewStore

  init(store: EditSession.Store, viewStore: EditSession.ViewStore) {
    self.store = store
    self.viewStore = viewStore
  }
  
  func makeUIView(context: Context) -> Engine.Picker<Resources.Leak, TitledImageView> {
    return Engine.Picker<Resources.Leak, TitledImageView>(
      store: store.scope(
        state: { state in
          .init(
            elements: Resources.Leak.all,
            currentElement: Resources.Leak.all.first(where: { state.filterParameters.lightLeak == $0.resource }) ?? Resources.Leak.all[0]
          )
        },
        action: { .set(\.$filterParameters.lightLeak, $0.resource) }
      ),
      map: { leak in .configuration(
        title: "",
        { self.leakThumbnail(resource: leak.resource) },
        queue: uiBackgroundQueue
      )},
      size: 60,
      spacing: 20
    ) ~~ { $0.collection.backgroundColor = .dazecam.dark }
  }

  func updateUIView(_ uiView: Engine.Picker<Resources.Leak, TitledImageView>, context: Context) { }
  
  let filters: [Named<Resources.Lut>] = [
    .init(value: Resources.Lut.faded, name: "palm"),
    .init(value: Resources.Lut.disposable4, name: "dunes"),
    //.init(value: Resources.Lut.disposable5, name: "joshua tree"),
    //.init(value: Resources.Lut.greenShadows, name: "aurora"),
    .init(value: Resources.Lut.pastel4, name: "mirage"),
    .init(value: Resources.Lut.hybrid1, name: "oasis"),
    .init(value: Resources.Lut.disposable17, name: "dawn"),
    .init(value: Resources.Lut.disposable18, name: "dusk"),
  ]
  
  private func leakThumbnail(resource: Resource) -> UIImage {
    let data = try? CIImage(contentsOf: resource.url)!
      .filter { image in
        size(.fillingAspect(.init(width: 100, height: 100)))
        ImageProcessor.position(.center(in: image.extent))
      }
      .render(compression: 1.0, renderer: .thumbnailQuality)
    return data.map(UIImage.init(data:))! ?? UIImage() // TODO
  }
}

struct StampPickerView: UIViewRepresentable {
  private let store: EditSession.Store
  private let viewStore: EditSession.ViewStore

  init(store: EditSession.Store, viewStore: EditSession.ViewStore) {
    self.store = store
    self.viewStore = viewStore
  }
  
  func makeUIView(context: Context) -> Engine.Picker<StampFont, UILabel> {
    return Engine.Picker<StampFont, UILabel>(
      store: store.scope(
        state: {
          .init(elements: StampFont.all, currentElement: $0.filterParameters.stampFont)
        },
        action: { .set(\.$filterParameters.stampFont, $0) }
      ),
      map: { .stampFont($0) },
      size: 60,
      spacing: 20
    ) ~~ { $0.collection.backgroundColor = .dazecam.dark }
  }

  func updateUIView(_ uiView: Engine.Picker<StampFont, UILabel>, context: Context) { }
}

struct EditCategoryView: View {
  let store: EditSession.Store
  
  init(store: EditSession.Store) {
    self.store = store
  }
  
  var body: some View {
    WithViewStore(store) { viewStore in
      let parameters = viewStore.binding(\.$filterParameters)
      switch viewStore.currentPanel {
      case .filter:
        FilterPanelView(
          binding: parameters.lookupIntensity,
          content: FilterPickerView(store: store, viewStore: viewStore)
        )
      case .leak:
        LeakPanelView(
          binding: parameters.lightLeakOpacity,
          content: LeakPickerView(store: store, viewStore: viewStore)
        )
      case .glow:
        GlowPanelView(
          threshold: parameters.glowThreshold,
          radius: parameters.glowRadius,
          intensity: parameters.glowOpacity
        )
      case .grain:
        GrainPanelView(
          size: parameters.grainSize,
          opacity: parameters.grainOpacity
        )
      case .blur:
        BlurPanelView(binding: parameters.blurRadius)
      case .chroma:
        ChromaPanelView(intensity: parameters.chromaScale)
      case .date:
        DatePanelView(
          fontPicker: StampPickerView(store: store, viewStore: viewStore),
          color: parameters.stampColor,
          dateVisible: parameters.stampDateVisible,
          timeVisible: parameters.stampTimeVisible
        )
      case .dust:
        DustPanelView(
          particles: parameters.dustParticleIntensity,
          hairs: parameters.dustHairIntensity,
          opacity: parameters.dustOpacity
        )
      case .vignette:
        VignettePanelView(
          intensity: parameters.vignetteIntensity
        )
      }
    }
    //.animation(.easeIn(duration: 0.15))
  }
}
