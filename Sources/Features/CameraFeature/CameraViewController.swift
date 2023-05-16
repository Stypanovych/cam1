import UIKit
import Engine
import Photos
import Combine
import ComposableArchitecture
import SwiftUI

public final class CameraViewController: CombineViewController {
  private let store: Capture.Store
  private let viewStore: Capture.ViewStore
  
  public init(store: Capture.Store) {
    self.store = store
    self.viewStore = ViewStore(store)
    super.init()
    setupViews()
    setupInputs()
    subscribeToViewStore()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  override public func viewSafeAreaInsetsDidChange() {
    questionMarkLabel.snp.remakeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide).inset(Theme.shared.unit)
      make.trailing.equalTo(view).inset(view.safeAreaInsets.bottom + Theme.shared.unit)
      make.bottom.trailing.equalToSuperview()
    }
  }
  
  private func subscribeToViewStore() {
    viewStore.publisher.preview
      .sink { [unowned self] usage in
        switch usage {
        case nil:
          self.usageLabel.isHidden = true
        case let .enabled(layer):
          self.usageLabel.isHidden = true
          self.viewFinderView.cameraView.update(with: layer)
        case .disabled:
          self.usageLabel.isHidden = false
        }
      }
      .store(in: &cancellables)
  }
  
  private func setupInputs() {
    viewWillAppearPublisher
      .sink { [unowned self] in
        self.viewStore.send(.setup)
      }
      .store(in: &cancellables)
    
    let doubleTap = UITapGestureRecognizer() ~~ { $0.numberOfTapsRequired = 2 }
    viewFinderView.gesture(.tap(doubleTap))
      .sink { [unowned self] _ in
        self.viewStore.send(.toggleOrientation)
      }
      .store(in: &cancellables)
    
    shutterButton.gesture(.tap())
      .sink { [unowned self] _ in
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        self.viewFinderView.cameraView.snap()
        self.viewStore.send(.capturePhoto(flash: false))
      }
      .store(in: &cancellables)
    
    let gesture = UILongPressGestureRecognizer() ~~ {
      $0.minimumPressDuration = 1.0
    }
    shutterButton.gesture(.longPress(gesture))
      .sink { [unowned self] output in
        guard output.get().state == .began else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        self.viewFinderView.cameraView.snap()
        self.viewStore.send(.capturePhoto(flash: true))
      }
      .store(in: &cancellables)
    
    collectionButton.gesture()
      .sink { [unowned self] _ in
        self.viewStore.send(.navigateToMain)
      }
      .store(in: &cancellables)
    
    questionMarkLabel.gesture()
      .sink { [unowned self] _ in
        self.addTutorialView()
      }
      .store(in: &cancellables)
  }
  
  private func setupViews() {
    view.backgroundColor = .dazecam.dark
    view.addSubview(viewFinderView)
    view.addSubview(usageLabel)
    view.addSubview(shutterButton)
    view.addSubview(collectionButton)
    view.addSubview(questionMarkLabel)
    
    let shutterButtonTopLayoutGuide = UILayoutGuide()
    let collectionButtonTopLayoutGuide = UILayoutGuide()
    let collectionButtonBottomLayoutGuide = UILayoutGuide()
    
    view.addLayoutGuide(shutterButtonTopLayoutGuide)
    view.addLayoutGuide(collectionButtonTopLayoutGuide)
    view.addLayoutGuide(collectionButtonBottomLayoutGuide)
    
    viewFinderView.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview().inset(Theme.shared.dimension.barHeight)
      make.height.equalTo(viewFinderView.snp.width).multipliedBy(4.0 / 3.0)
      make.bottom.equalTo(shutterButtonTopLayoutGuide.snp.top)
    }
    
    usageLabel.snp.makeConstraints { make in
      make.center.equalTo(viewFinderView.snp.center)
      make.leading.trailing.equalTo(viewFinderView).inset(Theme.shared.margins)
    }
    
    shutterButtonTopLayoutGuide.snp.makeConstraints { make in
      make.height.equalTo(collectionButtonTopLayoutGuide)
    }
    
    shutterButton.snp.makeConstraints { make in
      make.top.equalTo(shutterButtonTopLayoutGuide.snp.bottom)
      make.centerX.equalToSuperview()
      make.height.equalTo(.dazecam.unit * 10)
    }
    
    collectionButtonTopLayoutGuide.snp.makeConstraints { make in
      make.top.equalTo(shutterButton.snp.bottom)
      make.height.equalTo(collectionButtonBottomLayoutGuide)
    }
    
    collectionButton.snp.makeConstraints { make in
      make.top.equalTo(collectionButtonTopLayoutGuide.snp.bottom)
      make.centerX.equalToSuperview()
      make.height.equalTo(.dazecam.unit * 5)
      make.bottom.equalTo(collectionButtonBottomLayoutGuide.snp.top)
    }
    
    collectionButtonBottomLayoutGuide.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
    }
  }
  
  private lazy var viewFinderView = ViewFinderView() ~~ {
    $0.isUserInteractionEnabled = true
  }
  private lazy var shutterButton = ShutterButton()
  private lazy var collectionButton = CollectionButton()
  
  private lazy var shutterTutorialLabel = TutorialLabel(text: "Press and hold to capture photo with flash")
    .environmentObject(Theme.shared)
    .uiview(viewController: self)

//  private lazy var questionMarkLabel = UILabel() ~~ {
//    $0.text = "?"
//    $0.font = Theme.shared.font.main.uiFont
//    $0.textColor = Theme.shared.light
//    $0.isUserInteractionEnabled = true
//  }
  private lazy var questionMarkLabel = QuestionMarkButton()
    .environmentObject(Theme.shared)
    .uiview(viewController: self)
  
  private(set) lazy var usageLabel = UILabel() ~~ {
    $0.text = "Allow camera access in settings to use the camera"
    $0.textColor = .dazecam.light
    $0.font = .dazecam.main.mid.black.uiFont
    $0.textAlignment = .center
    $0.numberOfLines = 0
  }
  
  private func addTutorialView() {
    let shutterTutorialLabel = TutorialLabel(text: "Press and hold to capture photo with flash")
      .environmentObject(Theme.shared)
      .uiview(viewController: self)
    
    let previewTutorialLabel = TutorialLabel(text: "Double tap to toggle camera orientation")
      .environmentObject(Theme.shared)
      .uiview(viewController: self)
    
    let background = UIView() ~~ {
      $0.backgroundColor = .black.withAlphaComponent(0.5)
    }
    
    background.addSubview(previewTutorialLabel)
    background.addSubview(shutterTutorialLabel)
    view.addSubview(background)
    
    background.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    shutterTutorialLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(shutterButton.snp.top)
    }
    
    previewTutorialLabel.snp.makeConstraints { make in
      make.center.equalTo(viewFinderView)
    }
    
    background.gesture()
      .flatMap { _ in
        UIView.animate(0.3) {
          background.alpha = 0
        }
      }
      .sink { _ in
        background.removeFromSuperview()
      }
      .store(in: &cancellables)

    background.alpha = 0
    UIView.animate(withDuration: 0.3) {
      background.alpha = 1
    }
  }
}

struct QuestionMarkButton: View {
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    Text("?")
      .font(theme.main.large.black.uiFont.swiftui)
      .foregroundColor(theme.dark.swiftui)
      .padding(theme.unit)
      .background(Circle().fill(theme.extraDark.swiftui))
  }
}

struct TutorialLabel: View {
  let text: String
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    Text(text)
      .font(theme.main.mid.black.uiFont.swiftui)
      .foregroundColor(theme.dark.swiftui)
      //.fixedSize(horizontal: false, vertical: true)
      .padding(theme.unit * 2)
      .background(Capsule().fill(theme.light.swiftui))
  }
}
