import Engine
import UIKit
import SnapKit

class ShutterButton: UIButton {
  override var intrinsicContentSize: CGSize {
    return CGSize(width: frame.height, height: frame.height)
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
  
  private var addedMainCircle = false
  
  private var mainView = ShutterCircleView() ~~ {
    $0.isUserInteractionEnabled = false
  }
  
  private lazy var shadowView = ShadowView() ~~ {
    $0.isUserInteractionEnabled = false
    $0.addMotionEffect(motionEffect)
  }
  
  init() {
    super.init(frame: CGRect())
    
    addSubview(shadowView)
    addSubview(mainView)
    
    shadowView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    mainView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  override func layoutSubviews() {
    invalidateIntrinsicContentSize()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class ShadowView: UIView {
  let borderShape = CAShapeLayer()
  
  init(borderColor: UIColor = .dazecam.dark) {
    super.init(frame: CGRect())
    layer.addSublayer(borderShape)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    drawCircle()
  }
  
  private func drawCircle() {
    let center = CGPoint(
      x: bounds.width / 2,
      y: bounds.height / 2
    )
    let path = UIBezierPath(
      arcCenter: center,
      radius: bounds.height / 2,
      startAngle: 0,
      endAngle: 2 * CGFloat.pi,
      clockwise: true
    )
    borderShape.path = path.cgPath
    borderShape.fillColor = Theme.shared.color.shadowDark.cgColor
  }
}

class ShutterCircleView: UIView {
  private var borderColor: UIColor
  private var borderWidth: CGFloat = .dazecam.unit
  private let borderShape = CAShapeLayer()
  
  private lazy var ringShadowView = RingShadowView() ~~ {
    $0.addMotionEffect(motionEffect)
  }
  
  private lazy var motionEffect: UIMotionEffectGroup = {
    let min = CGFloat(9)
    let max = CGFloat(-9)
    
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
  
  init(borderColor: UIColor = .dazecam.dark) {
    self.borderColor = borderColor
    super.init(frame: CGRect())
    //backgroundColor = UIColor.red
    clipsToBounds = true
    addSubview(ringShadowView)
    layer.addSublayer(borderShape)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    ringShadowView.frame = bounds
    drawCircle()
  }
  
  private func drawCircle() {
    let center = CGPoint(
      x: bounds.width / 2,
      y: bounds.height / 2
    )
    let path = UIBezierPath(
      arcCenter: center,
      radius: bounds.height / 2,
      startAngle: 0,
      endAngle: 2 * CGFloat.pi,
      clockwise: true
    )
    let circlePath = UIBezierPath(
      arcCenter: center,
      radius: bounds.height / 2 - borderWidth / 2,
      startAngle: 0,
      endAngle: 2 * CGFloat.pi,
      clockwise: true
    )
    
    let maskPath = CGMutablePath()
    maskPath.addPath(path.cgPath)
    
    let maskLayer = CAShapeLayer()
    maskLayer.path = maskPath
    maskLayer.fillRule = .evenOdd
    layer.mask = maskLayer
    
    //borderShape.frame = bounds
    borderShape.path = circlePath.cgPath
    borderShape.strokeColor = borderColor.cgColor
    borderShape.fillColor = UIColor.clear.cgColor
    borderShape.lineWidth = borderWidth
  }
}

class RingShadowView: UIView {
  private var color: UIColor
  private var borderWidth: CGFloat = .dazecam.unit
  private let borderShape = CAShapeLayer()
  
  init(color: UIColor = .dazecam.shadowDark) {
    self.color = color
    super.init(frame: CGRect())
    layer.addSublayer(borderShape)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    drawRing()
  }
  
  private func drawRing() {
    let center = CGPoint(
      x: bounds.width / 2,
      y: bounds.height / 2
    )
    let path = UIBezierPath(
      arcCenter: center,
      radius: bounds.height / 2 - borderWidth / 2,
      startAngle: 0,
      endAngle: 2 * CGFloat.pi,
      clockwise: true
    )
    borderShape.frame = bounds
    borderShape.path = path.cgPath
    borderShape.strokeColor = color.cgColor
    borderShape.fillColor = Theme.shared.color.light.cgColor
    borderShape.lineWidth = borderWidth
  }
}
