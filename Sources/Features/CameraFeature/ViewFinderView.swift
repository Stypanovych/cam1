import UIKit
import Engine

class ViewFinderView: UIView {
  private lazy var openingView = OpeningView() ~~ {
    $0.backgroundColor = .dazecam.dark
  }
  
  private(set) lazy var cameraView = CameraView() ~~ {
    $0.backgroundColor = .black
    $0.addMotionEffect(motionEffect)
  }
  
  private lazy var motionEffect: UIMotionEffectGroup = {
    let min = CGFloat(12)
    let max = CGFloat(-12)
    
    let xMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.x", type: .tiltAlongHorizontalAxis)
    xMotion.minimumRelativeValue = min
    xMotion.maximumRelativeValue = max
    
    let yMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.y", type: .tiltAlongVerticalAxis)
    yMotion.minimumRelativeValue = min
    yMotion.maximumRelativeValue = max
    
    let motionEffectGroup = UIMotionEffectGroup()
    motionEffectGroup.motionEffects = [xMotion,yMotion]
    return motionEffectGroup
  }()
  
  init() {
    super.init(frame: CGRect())
    backgroundColor = .dazecam.shadowDark
    clipsToBounds = true
    
    addSubview(cameraView)
    addSubview(openingView)
    
    openingView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    cameraView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class OpeningView: UIView {
  override func layoutSubviews() {
    super.layoutSubviews()
    let roundedRectPath = UIBezierPath(roundedRect: bounds, cornerRadius: .dazecam.margins)
    
    let path = CGMutablePath()
    path.addRect(bounds)
    path.addPath(roundedRectPath.cgPath)
    
    let maskLayer = CAShapeLayer()
    maskLayer.path = path
    maskLayer.fillRule = .evenOdd
    
    layer.mask = maskLayer
  }
}

class CameraView: CALayerView {
  private(set) lazy var topShutter = UIView() ~~ {
    $0.backgroundColor = .dazecam.shadowDark
  }
  
  private(set) lazy var bottomShutter = UIView() ~~ {
    $0.backgroundColor = .dazecam.shadowDark
  }
  
  override init() {
    super.init()
    
    addSubview(topShutter)
    addSubview(bottomShutter)
    
    layoutTopShutter(closed: false)
    layoutBottomShutter(closed: false)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    let roundedRectPath = UIBezierPath(roundedRect: bounds, cornerRadius: .dazecam.margins)
    
    let path = CGMutablePath()
    path.addPath(roundedRectPath.cgPath)
    
    let maskLayer = CAShapeLayer()
    maskLayer.path = path
    
    layer.mask = maskLayer
  }
  
  func snap() {
    closeShutter {
      self.openShutter()
    }
  }

  private func layoutTopShutter(closed: Bool) {
    topShutter.snp.remakeConstraints { make in
      make.leading.trailing.top.equalToSuperview()
      make.height.equalToSuperview().multipliedBy(closed ? 0.5 : 0)
    }
  }
  
  private func layoutBottomShutter(closed: Bool) {
    bottomShutter.snp.remakeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.height.equalToSuperview().multipliedBy(closed ? 0.5 : 0)
    }
  }
  
  private func closeShutter(completion: @escaping () -> Void) {
    layoutTopShutter(closed: true)
    layoutBottomShutter(closed: true)
    UIView.animate(
      withDuration: 0.1,
      animations: { self.layoutIfNeeded() },
      completion:  { _ in completion() }
    )
  }
  
  private func openShutter() {
    layoutTopShutter(closed: false)
    layoutBottomShutter(closed: false)
    UIView.animate(withDuration: 0.1) {
      self.layoutIfNeeded()
    }
  }
}
