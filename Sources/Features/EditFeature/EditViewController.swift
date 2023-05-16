import UIKit
import ComposableArchitecture
import Combine
import Engine
import SwiftUI
import DazeFoundation

extension Cell.Configuration where View == PresetView {
  static func preset(_ preset: Preset) -> Cell<PresetView>.Configuration {
    return .init(
      createView: {
        PresetView() ~~ {
          $0.configure(preset)
        }
      },
      configure: {
        $0.configure(preset)
        return nil
      },
      prepareForReuse: { _ in }
    )
  }
}

extension Cell.Configuration where View == UILabel {
  static func editCategory(text: String) -> Cell<UILabel>.Configuration {
    .init(
      createView: {
        UILabel() ~~ {
          $0.text = text.uppercased()
          $0.baselineAdjustment = .alignCenters
          $0.textAlignment = .center
          $0.font = .dazecam.main.small.black.uiFont
          $0.textColor = .dazecam.light
        }
      },
      configure: {
        $0.text = text.uppercased()
        return nil
      },
      prepareForReuse: { _ in }
    )
  }
  
  static func stampFont(_ font: StampFont) -> Cell<UILabel>.Configuration {
    .init(
      createView: {
        UILabel() ~~ {
          $0.text = font.rawValue.uppercased()
          $0.textAlignment = .center
          $0.font = font.uiFont.withSize(15)
          $0.textColor = .dazecam.light
        }
      },
      configure: {
        $0.text = font.rawValue.uppercased()
        $0.font = font.uiFont.withSize(15)
        return nil
      },
      prepareForReuse: { _ in }
    )
  }
}

typealias EffectsPicker = Engine.Picker<EditPanel, UILabel>
typealias PresetsPicker = Engine.Picker<Preset, PresetView>

public struct EditCollectionView: UIViewRepresentable {
  private let store: Store<EditCollection.State, EditCollection.Action>

  public init(store: Store<EditCollection.State, EditCollection.Action>) {
    self.store = store
  }
  
  public func makeUIView(context: Context) -> EditCollection {
    return EditCollection(store: store)
  }

  public func updateUIView(_ uiView: EditCollection, context: Context) {}
}

public final class EditCollection: CombineView {
  public typealias State = Edit.State
  public typealias Action = Edit.Action
  
  private let store: Store<State, Action>
  private let viewStore: ViewStore<State, Action>

  public init(store: Store<State, Action>) {
    self.store = store
    self.viewStore = ViewStore(store)
    super.init()
    setupViews()
    //setupInputs()
    subscribeToViewStore()
  }

  private func subscribeToViewStore() {
    Publishers.CombineLatest(
      viewStore.publisher.elements,
      layoutSubviewsPublisher
    )
      .map { $0.0 }
      .map { [unowned self] elements in
        elements.map { $0.lazyImage(for: \.filteredImagePath.path, sizeToFit: self.bounds.size) }
      }
      .withLatestFrom(viewStore.publisher.currentElement) // withLatestFrom(renderedImage)
      .sink { [unowned self] lazyImages, currentElement in
        let payloads: [CollectionView.Element<EditImageCollectionViewCell>] = lazyImages.reversed().map { lazyImage in
          .init (
            id: lazyImage.value.id,
            configure: { cell in
              cell.configure(
                with: lazyImage.future,
                preview: (self.viewStore.currentElementId == lazyImage.value.id) ? self.preview : nil
              )
            },
            didSelect: { [unowned self] in
              guard self.viewStore.editSession == nil else { return }
              self.startEditSession()
            },
            didBecomeVisible: { [unowned self] in
              //guard didLayout else { return } // already layed out -> already scrolled to first page
              self.viewStore.send(.scroll(to: lazyImage.value.id)) // ex. after delete
            }
          )
        }
        self.collectionView.update(with: payloads) // do not want to animate after edit
        
        self.layoutIfNeeded()
        guard let indexPath = self.currentIndexPath() else { return }
        self.collectionView.scrollToItem(
          at: indexPath,
          at: .left,
          animated: false
        )
      }
      .store(in: &cancellables)

    viewStore.publisher.editSession
      .map { $0 == nil }
      .sink { [unowned self] isEditSessionActive in
        self.collectionView.isScrollEnabled = isEditSessionActive
      }
      .store(in: &cancellables)

    store.scope(state: \.editSession, action: Edit.Action.editSession).ifLet(
      then: { [unowned self] in self.setupEditSession(with: $0) },
      else: { [unowned self] in self.removeEditSession() }
    )
    .store(in: &cancellables)
    
    //editTappedPublisher
  }
  
  private func setupEditSession(with editSessionStore: EditSession.Store) {
    guard let cell = currentCell() else { return }
    let editSessionViewStore = ViewStore(editSessionStore)
    // add filtered frame
//    let preview = cell.addPreview(
//      context: editSessionViewStore.env.renderContext,
//      renderScheduler: editSessionViewStore.env.renderScheduler,
//      mainScheduler: editSessionViewStore.env.mainScheduler
//    )
    
    let previewView = PreviewView(
      device: MTLCreateSystemDefaultDevice()!,
      context: editSessionViewStore.env.renderContext,
      renderScheduler: editSessionViewStore.env.renderScheduler,
      mainScheduler: editSessionViewStore.env.mainScheduler
    )
    
    let longPress = UILongPressGestureRecognizer() ~~ {
      $0.minimumPressDuration = 0.05
      $0.numberOfTapsRequired = 0
    }
    
    preview = .init(view: previewView, longPress: longPress)
    cell.add(preview: preview!)
    
    editSessionViewStore.send(.renderSize(self.renderSize()))
    preview?.view.layoutSubviewsPublisher
      .sink { [unowned editSessionViewStore, unowned self] _ in
        editSessionViewStore.send(.renderSize(self.renderSize()))
      }
      .store(in: &cancellables)
    
    editSessionViewStore.publisher.imageToRender
      .compactMap { $0 }
      .sink { [unowned self] in self.preview?.view.add(frame: $0) }
      .store(in: &cancellables)
    
    editSessionViewStore.send(.render)
    
    cell.contentView
      .gesture(.longPress(preview!.longPress))
      .map { $0.get().state }
      .sink { [unowned editSessionViewStore] state in
        switch state {
        case .began: editSessionViewStore.send(.showOriginal)
        case .ended: editSessionViewStore.send(.showFiltered)
        default: break
        }
      }
      .store(in: &cancellables)
  }
  
  private func startEditSession() {
    self.viewStore.send(.edit(.start))
  }

  private func removeEditSession() {
    let cell = currentCell()

    // TODO: do we need this replacementImage?
    self.viewStore.currentElement.lazyImage(for: \.filteredImagePath.path).future
      .replaceError(with: UIImage())
      .sink { [unowned self] image in
        cell?.imageView.image = image
        cell?.removePreview()
        self.preview = nil
        cell?.layoutIfNeeded()
      }
      .store(in: &cancellables)
  }
  
  private func currentIndexPath() -> IndexPath? {
    collectionView.indexPath(for: viewStore.currentElement.lazyImage(for: \.filteredImagePath.path).value.id)
  }
  
  private func currentCell() -> EditImageCollectionViewCell? {
    guard let indexPath = currentIndexPath() else { return nil }
    return collectionView.cellForItem(at: indexPath) as? EditImageCollectionViewCell
  }
  
  private func renderSize() -> CGFloat {
    guard let cell = currentCell() else { return 0 }
    let bounds = cell.imageView.bounds
    return bounds.height.pointsToPixels() * bounds.width.pointsToPixels()
  }
  
  private func setupViews() {
    addSubview(collectionView)
    
    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    layoutIfNeeded()
  }
  
  private var preview: EditImageCollectionViewCell.Preview?
  
  private lazy var collectionView = PagedCollectionView(scrollDirection: .horizontal) ~~ {
    $0.contentInsetAdjustmentBehavior = .never
    $0.backgroundColor = .dazecam.dark
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

public final class EditViewController: CombineViewController {
  public typealias State = Edit.State
  public typealias Action = Edit.Action
  
  private let store: Store<State, Action>
  private let viewStore: ViewStore<State, Action>

  public init(store: Store<State, Action>) {
    self.store = store
    self.viewStore = ViewStore(store)
    super.init()
    setupViews()
  }
  
  private func setupViews() {
    view.backgroundColor = .dazecam.light
    view.addSubview(editBar)
    
    editBar.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private lazy var editBar = EditControlsView(
    store: store,
    addPresetAction: { [unowned self] in self.presetNameAlert() }
  )
    .environmentObject(Theme.shared).uiview(viewController: self)
  
  private var presetNameValidPublisher = CurrentValueSubject<Bool, Never>(false)
  
  func presetNameAlert() {
    var nameTextField: UITextField!
    let alert = UIAlertController(title: "Add Preset", message: nil, preferredStyle: .alert) ~~ {
      $0.addTextField { textField in
        textField.placeholder = "Name"
        textField.delegate = self
        nameTextField = textField
      }
      $0.addAction(.init(title: "Cancel", style: .cancel))
      let saveAction = UIAlertAction(
        title: "Save",
        style: .default,
        handler: { [unowned self] _ in self.viewStore.send(.newPreset(nameTextField.text!)) }
      ) ~~ { saveAction in
        presetNameValidPublisher
          .sink { saveAction.isEnabled = $0 }
          .store(in: &cancellables)
      }
      $0.addAction(saveAction)
    }
    present(alert, animated: true, completion: nil)
  }
}

extension EditViewController: UITextFieldDelegate {
  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let newString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let maxLength = 15
    let nameIsValid = (1...maxLength).contains(newString.count)
    presetNameValidPublisher.send(nameIsValid)
    return newString.count < maxLength
  }
}

func animate(_ block: @escaping () -> Void) {
  UIView.animate(withDuration: Theme.shared.animation.time) {
    block()
  }
}

struct EffectsPickerView: UIViewRepresentable {
  private let store: Store<EffectsPicker.State, EffectsPicker.Action>

  init(store: Store<EffectsPicker.State, EffectsPicker.Action>) {
    self.store = store
  }
  
  func makeUIView(context: Context) -> EffectsPicker {
    return EffectsPicker(
      store: store,
      map: { .editCategory(text: $0.rawValue) },
      size: 50,
      spacing: 0
    ) ~~ {
      $0.collection.showsHorizontalScrollIndicator = true
      $0.collection.backgroundColor = .dazecam.dark
      $0.layer.cornerRadius = Theme.shared.unit
      $0.layer.cornerCurve = .continuous
    }
  }

  func updateUIView(_ uiView: EffectsPicker, context: Context) { }
}

struct PresetsPickerView: UIViewRepresentable {
  private let store: Store<PresetsPicker.State, PresetsPicker.Action>

  init(store: Store<PresetsPicker.State, PresetsPicker.Action>) {
    self.store = store
  }
  
  func makeUIView(context: Context) -> PresetsPicker {
    return PresetsPicker(
      store: store,
      map: { .preset($0) },
      size: 50,
      spacing: 10
    ) ~~ {
      $0.collection.showsHorizontalScrollIndicator = true
      $0.collection.backgroundColor = .dazecam.red
      $0.layer.cornerRadius = Theme.shared.unit
      $0.layer.cornerCurve = .continuous
    }
  }

  func updateUIView(_ uiView: PresetsPicker, context: Context) { }
}

typealias EffectsPickerStore = ComposableArchitecture.Store<EffectsPicker.State, EffectsPicker.Action>
typealias PresetsPickerStore = ComposableArchitecture.Store<PresetsPicker.State, PresetsPicker.Action>

struct EditBar: View {
  typealias ViewState = Edit.State
  typealias Action = Edit.Action

  typealias Store = ComposableArchitecture.Store<ViewState, Action>
  typealias ViewStore = ComposableArchitecture.ViewStore<ViewState, Action>
  
  let store: Store
  @State private var maxButtonWidth: CGFloat?

  let addPresetAction: () -> Void
  let editAction: () -> Void
  
  @EnvironmentObject private var theme: Theme
  
  @Namespace private var namespace
  
  private enum Geometry {
    case buttons
  }
  
  init(
    store: Store,
    editAction: @escaping () -> Void,
    addPresetAction: @escaping () -> Void
  ) {
    self.store = store
    self.editAction = editAction
    self.addPresetAction = addPresetAction
  }
  
  @ViewBuilder
  func edit(_ viewStore: ViewStore) -> some View {
    let imageOptionsViewStore: ImageOptionsView.Store = store.scope(
      state: {
        .init(
          optionsVisible: true,
          downloadOptions: $0.downloadOptions
        )
      },
      action: Action.image
    )
    ImageOptionsView(store: imageOptionsViewStore) {
      DazeButton("EDIT") {
        editAction() // TODO: Add edit tool to EditSessionCore
      }
    }
    .frame(height: theme.barHeight)
    //.transition(.delayedFade)
    //.matchedGeometryEffect(id: Geometry.buttons, in: namespace)
  }
  
  @ViewBuilder
  func picker(
    _ viewStore: EditSession.ViewStore,
    effectsPickerStore: EffectsPickerStore,
    presetsPickerStore: PresetsPickerStore
  ) -> some View {
    VStack {
      Margin(0.5)
      Group {
        switch viewStore.tool {
        case .effects:
          EffectsPickerView(store: effectsPickerStore)
        case .presets:
          ZStack {
            PresetsPickerView(store: presetsPickerStore)
            //let preset
            if case .custom(_) = viewStore.currentPreset {
              HStack {
                Spacer()
                VStack {
                  Margin(0.25)
                  Text("+")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fill)
                    .background(theme.light.swiftui)
                    .fixedSize(horizontal: true, vertical: false)
                    .font(theme.main.large.black.uiFont.swiftui)
                    .foregroundColor(theme.red.swiftui)
                    .clipShape(RoundedRectangle(cornerRadius: theme.unit))
                    .hapticTap(addPresetAction)
                  Margin(0.25)
                }
                Margin(0.25)
              }
            }
          }
        }
      }
      .frame(height: theme.unit * 4)
    }
  }
  
  @ViewBuilder
  func cancel(
    _ viewStore: ViewStore,
    _ editSessionViewStore: EditSession.ViewStore,
    effectsPickerStore: EffectsPickerStore,
    presetsPickerStore: PresetsPickerStore
  ) -> some View {
    picker(editSessionViewStore, effectsPickerStore: effectsPickerStore, presetsPickerStore: presetsPickerStore)
      .transition(.delayedFade)
    editingEnabledButtons(viewStore, editSessionViewStore)
  }
  
  func editingEnabledButtons(
    _ viewStore: ViewStore,
    _ editSessionViewStore: EditSession.ViewStore
  ) -> some View {
    ZStack {
      HStack {
        DazeButton("CANCEL") {
          viewStore.send(.edit(.cancel))
        }
        Spacer()
        DazeButton("SAVE") {
          viewStore.send(.edit(.save))
        }
      }
      VStack {
        let editTool = editSessionViewStore.tool
        Margin(0.5)
        Text(editTool.toggled.name)
          .padding(theme.unit)
          .background(editTool.toggled.background(theme))
          .font(theme.main.small.black.uiFont.swiftui)
          .foregroundColor(theme.light.swiftui)
          .clipShape(RoundedRectangle(cornerRadius: theme.unit))
          .hapticTap { editSessionViewStore.send(.set(\.$tool, editTool.toggled)) }
        Margin(0.5)
      }
    }
    .frame(height: theme.barHeight)
    //.transition(.delayedFade)
    .transition(.opacity)
    .matchedGeometryEffect(id: Geometry.buttons, in: namespace)
  }
  
  func effectsPickerStore(_ editSessionStore: EditSession.Store) -> EffectsPickerStore {
    return editSessionStore.scope(
      state: {
        .init(
          elements: $0.panels,
          currentElement: $0.currentPanel
        )
      },
      action: { .set(\.$currentPanel, $0) }
    )
  }
     
  func presetsPickerStore(_ editSessionStore: EditSession.Store) -> PresetsPickerStore {
    return editSessionStore.scope(
      state: {
        .init(
          elements: $0.presets,
          currentElement: $0.currentPreset
        )
      },
      action: { .set(\.$currentPreset, $0) }
    )
  }
  
  var body: some View {
    WithViewStore(store) { viewStore in
      //ZStack {

      HStack {
          Margin()
          VStack {
            IfLetStore(
              store.scope(
                state: \.editSession,
                action: Edit.Action.editSession
              ),
              then: { editSessionStore in
                let effectsPickerStore: EffectsPickerStore = effectsPickerStore(editSessionStore)
                let presetsPickerStore: PresetsPickerStore = presetsPickerStore(editSessionStore)
                WithViewStore(editSessionStore) { editSessionViewStore in
                  cancel(viewStore, editSessionViewStore, effectsPickerStore: effectsPickerStore, presetsPickerStore: presetsPickerStore)
                }
              },
              else: {
                edit(viewStore)
                  .transition(.opacity)
                  .matchedGeometryEffect(id: Geometry.buttons, in: namespace)
              }
            )
          }
          .animation(.dazecamDefault)
          Margin()
        }
        .background(
          theme.color.light.swiftui
            .animation(
              viewStore.editSession != nil ? .dazecamDefault : .dazecamDefault.delay(Animation.dazecam),
              value: viewStore.editSession != nil
            )
        )
      //}
    }
    //.animation(.easeIn(duration: 0.15))
  }
}

extension Animation {
  static let dazecam: Double = 0.15
  static let dazecamDefault: Self = .easeInOut(duration: dazecam)
}

private struct ButtonWidthPreferenceKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

//struct PresetNameInput: View {
//  let text: Binding<String>
//
//  var body: some View {
//    TextField("Name", text: text)
//  }
//}
//
//extension View {
//  func presetNameInput(text: Binding<String>, isPresented: Binding<Bool>) -> some View {
//    ZStack {
//      self
//      if isPresented.wrappedValue {
//        PresetNameInput(text: text)
//      }
//    }
//  }
//}
