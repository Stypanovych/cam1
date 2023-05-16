import UIKit

open class CALayerView: UIView {
  private var supplementaryLayer: CALayer?
  
  public init() {
    super.init(frame: .zero)
  }
  
  override open func layoutSubviews() {
    supplementaryLayer?.frame = bounds
  }
  
  open func update(with layer: CALayer) {
    supplementaryLayer?.removeFromSuperlayer()
    supplementaryLayer = layer
    self.layer.insertSublayer(supplementaryLayer!, at: 0)
    setNeedsLayout()
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
