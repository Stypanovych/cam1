import UIKit
import Engine

class PresetView: UIView {
  init() {
    super.init(frame: .zero)
    addSubview(labelContainer)
    labelContainer.addSubview(label)
    
//    labelContainer.snp.makeConstraints { make in
//      make.center.equalToSuperview()
//      make.top.equalTo(label).offset(-5)
//      make.bottom.equalTo(label).offset(5)
//      make.leading.equalTo(label).offset(-10)
//      make.trailing.equalTo(label).offset(10)
//      //make.height.equalTo(20)
//      //make.width.equalTo(50)
//    }
//
//    label.snp.makeConstraints { make in
//      make.center.equalToSuperview()
//    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    labelContainer.layer.cornerRadius = labelContainer.frame.height / 2
  }
  
  func configure(_ preset: Preset) {
    switch preset {
    case .custom:
      label.text = preset.name.uppercased()
      labelContainer.backgroundColor = .dazecam.light
      label.textColor = .dazecam.red
      label.font = .dazecam.main.small.black.uiFont
    case .user:
      label.text = preset.name
      labelContainer.backgroundColor = nil
      label.textColor = .dazecam.light
      label.font = .dazecam.main.mid.black.uiFont
    case .system:
      label.text = preset.name
      labelContainer.backgroundColor = nil
      label.textColor = .dazecam.dark
      label.font = .dazecam.main.mid.black.uiFont
    }
    
//    label.snp.remakeConstraints { make in
//      make.center.equalToSuperview()
//    }
    remakeConstraints(preset)
  }
  
  private func remakeConstraints(_ preset: Preset) {
    switch preset {
    case .user, .system:
      labelContainer.snp.remakeConstraints { make in
        make.edges.equalToSuperview()
      }
      label.snp.remakeConstraints { make in
        make.edges.equalToSuperview()
      }
    case .custom:
      labelContainer.snp.remakeConstraints { make in
        make.center.equalToSuperview()
        make.top.equalTo(label).offset(-5)
        make.bottom.equalTo(label).offset(5)
        make.leading.equalTo(label).offset(-10)
        make.trailing.equalTo(label).offset(10)
      }
      label.snp.remakeConstraints { make in
        make.center.equalToSuperview()
      }
    }
  }
  
  private lazy var labelContainer = UIView() ~~ {
    $0.layer.cornerCurve = .continuous
  }
  
  private lazy var label = UILabel() ~~ {
    $0.baselineAdjustment = .alignCenters
    $0.textAlignment = .center
    $0.adjustsFontSizeToFitWidth = true
  }
}
