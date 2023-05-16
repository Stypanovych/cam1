import UIKit
import Combine

public class Button: UIControl {
  private let title: String
  
  private var cancellables: Set<AnyCancellable> = []
  
  private let lightHaptic = UIImpactFeedbackGenerator(style: .light) ~~ {
    $0.prepare()
  }
  
  private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium) ~~ {
    $0.prepare()
  }
  
  public override var intrinsicContentSize: CGSize {
    return label.intrinsicContentSize
  }
  
  public init(title: String) {
    self.title = title
    super.init(frame: .zero)
    setupInputs()
    setupViews()
  }
  
  private func setupInputs() {
    publisher(for: .touchDown)
      .sink { [unowned self] _ in
        self.lightHaptic.impactOccurred()
        mediumHaptic.prepare()
      }
      .store(in: &cancellables)
    
    publisher(for: .touchUpInside)
      .sink { [unowned self] _ in
        self.mediumHaptic.impactOccurred()
        lightHaptic.prepare()
      }
      .store(in: &cancellables)
  }
  
  private func setupViews() {
    addSubview(label)
    
    label.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  private lazy var label = UILabel() ~~ {
    $0.text = title.uppercased()
    $0.baselineAdjustment = .alignCenters
    $0.font = .dazecam.main.black.large.uiFont
    $0.textColor = .dazecam.dark
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
