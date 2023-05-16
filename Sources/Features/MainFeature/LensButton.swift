import UIKit
import Engine

class LensButton: UIButton {
  private var lensView = LensView()
  
  init() {
    super.init(frame: CGRect())
    lensView.isUserInteractionEnabled = false
    addSubview(lensView)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    lensView.frame = bounds
  }
}

class LensView: UIView {
  private lazy var lensShadow: LensShadowView = {
    let shadow = LensShadowView()
    shadow.addMotionEffect(motionEffect)
    return shadow
  }()
  
  private lazy var motionEffect: UIMotionEffectGroup = {
    let min = CGFloat(5)
    let max = CGFloat(-5)
    
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
  
  private lazy var lensRim: LensRimView = LensRimView(rimWidth: rimWidth)
  
  private let rimWidth: CGFloat = 4.5
  
  init() {
    super.init(frame: CGRect())
    addSubview(lensShadow)
    addSubview(lensRim)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    lensShadow.frame = bounds
    lensRim.frame = bounds
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class LensShadowView: UIView {
  let borderShape = CAShapeLayer()
  
  init() {
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
    let center = CGPoint(x: bounds.width/2, y: bounds.height/2)
    let path = UIBezierPath(
      arcCenter: center,
      radius: bounds.height / 2,
      startAngle: 0,
      endAngle: 2 * CGFloat.pi,
      clockwise: true
    )
    borderShape.path = path.cgPath
    borderShape.fillColor = Theme.shared.logoDark.cgColor
  }
}

class LensRimView: UIView {
  var borderWidth = Theme.shared.unit/2
  
  let borderShape = CAShapeLayer()
  
  private lazy var rimShadowView: LensGlassView = {
    let rim = LensGlassView(rimWidth: borderWidth)
    rim.addMotionEffect(motionEffect)
    return rim
  }()
  
  private lazy var motionEffect: UIMotionEffectGroup = {
    let min = CGFloat(3)
    let max = CGFloat(-3)
    
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
  
  init(rimWidth: CGFloat) {
    borderWidth = rimWidth
    super.init(frame: CGRect())
    //backgroundColor = UIColor.red
    clipsToBounds = true
    addSubview(rimShadowView)
    layer.addSublayer(borderShape)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    rimShadowView.frame = bounds
    drawCircle()
  }
  
  private func drawCircle() {
    let center = CGPoint(x: bounds.width/2, y: bounds.height/2)
    let path = UIBezierPath(arcCenter: center, radius: bounds.height/2, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true)
    
    let circlePath = UIBezierPath(arcCenter: center, radius: bounds.height/2-borderWidth/2, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true)
    
    let maskPath = CGMutablePath()
    maskPath.addPath(path.cgPath)
    
    let maskLayer = CAShapeLayer()
    maskLayer.path = maskPath
    maskLayer.fillRule = .evenOdd
    layer.mask = maskLayer
    
    //borderShape.frame = bounds
    borderShape.path = circlePath.cgPath
    borderShape.strokeColor = Theme.shared.light.cgColor
    borderShape.fillColor = UIColor.clear.cgColor
    borderShape.lineWidth = borderWidth
  }
}

class LensGlassView: UIView {
  var borderWidth = Theme.shared.unit/2
  let borderShape = CAShapeLayer()
  
  private lazy var imageView: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "Glass")!)
    imageView.translatesAutoresizingMaskIntoConstraints = true
    return imageView
  }()
  
  init(rimWidth: CGFloat) {
    borderWidth = rimWidth
    super.init(frame: CGRect())
    addSubview(imageView)
    layer.addSublayer(borderShape)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    imageView.frame = CGRect(
      x: borderWidth,
      y: borderWidth,
      width: bounds.width - 2 * borderWidth,
      height: bounds.height - 2 * borderWidth
    )
    drawRing()
  }
  
  private func drawRing() {
    let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    let path = UIBezierPath(
      arcCenter: center,
      radius: bounds.height / 2 - borderWidth / 2,
      startAngle: 0,
      endAngle: 2 * CGFloat.pi,
      clockwise: true
    )
    borderShape.frame = bounds
    borderShape.path = path.cgPath
    borderShape.strokeColor = Theme.shared.logoDark.cgColor
    borderShape.fillColor = UIColor.clear.cgColor
    borderShape.lineWidth = borderWidth
  }
}
