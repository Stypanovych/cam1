import UIKit

public class ZoomView: UIScrollView, UIScrollViewDelegate {
  let view: UIView
  
  public init(_ view: UIView) {
    self.view = view
    super.init(frame: .zero)
    minimumZoomScale = 1.0
    maximumZoomScale = 6.0
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    delegate = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return view
  }
}

//extension ZoomView {
//  public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//    let hitTargetView = super.hitTest(point, with: event)
//    return hitTargetView as? UIControl ?? (hitTargetView == self ? nil : superview)
//  }
//
//  public override func didMoveToSuperview() {
//    superview?.addGestureRecognizer(panGestureRecognizer)
//  }
//}

//extension ZoomView: UIGestureRecognizerDelegate {
//  public func gestureRecognizer(
//    _ gestureRecognizer: UIGeostureRecognizer,
//    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
//  ) -> Bool {
//    true
//  }
//}
