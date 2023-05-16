import Combine
import UIKit

public let uiBackgroundQueue = DispatchQueue.background(.serial("com.DAZE35.ui"), .userInteractive)

open class CombineViewController: UIViewController {
  public var cancellables: [AnyCancellable] = []
  public let viewWillAppearPublisher = PassthroughSubject<Void, Never>()
  public let viewDidAppearPublisher = PassthroughSubject<Void, Never>()
  public let viewDidDisappearPublisher = PassthroughSubject<Void, Never>()
  
  public init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewWillAppearPublisher.send()
  }
  
  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewDidAppearPublisher.send()
  }
  
  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    viewDidDisappearPublisher.send()
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

public extension CombineViewController {
  func remove(notificationView: UIView, from barView: UIView) {
    UIView
      .animate(0.3, delay: 1.5) { [weak self] in
        guard let self = self else { return }
        notificationView.snp.remakeConstraints { make in
          make.leading.trailing.equalToSuperview()
          make.top.equalTo(barView)
        }
        self.view.layoutIfNeeded()
      }
      .sink { _ in
        notificationView.removeFromSuperview()
      }
      .store(in: &self.cancellables)
  }
  
  func add(notification: Engine.Notification, onto barView: UIView) -> UIView {
    let notificationView = NotificationView(notification: notification)
      .environmentObject(Theme.shared)
      .uiview(viewController: self)
    view.insertSubview(notificationView, belowSubview: barView)
    func layoutHidden() {
      notificationView.snp.makeConstraints { make in
        make.leading.trailing.equalToSuperview()
        make.top.equalTo(barView)
      }
    }
    func layoutRevealed() {
      notificationView.snp.remakeConstraints { make in
        make.leading.trailing.equalToSuperview()
        make.bottom.equalTo(barView.snp.top)
      }
    }
    layoutHidden()
    view.layoutIfNeeded()
    UIView
      .animate(0.3) { [weak self] in
        layoutRevealed()
        self?.view.layoutIfNeeded()
      }
      .sink { _ in }
      .store(in: &cancellables)
    return notificationView
  }
}

open class CombineView: UIView {
  public var cancellables: [AnyCancellable] = []
  public let layoutSubviewsPublisher = PassthroughSubject<CombineView, Never>()
  
  public init() {
    super.init(frame: .zero)
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    layoutSubviewsPublisher.send(self)
  }
}
