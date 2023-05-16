import UIKit
import Combine

public final class MultiGesture {
  private let gestures: [UIGestureRecognizer]
  private weak var view: UIView?
  
  public let movedPublisher = PassthroughSubject<CGPoint, Never>()
  public let endedPublisher = PassthroughSubject<CGPoint, Never>()
  
  public init(gestures: [UIGestureRecognizer]) {
    self.gestures = gestures
  }
  
  public func add(to view: UIView) {
    self.view = view
    gestures.forEach {
      $0.addTarget(self, action: #selector(viewGestured(_:)))
      view.addGestureRecognizer($0)
    }
  }
  
  public func remove() {
    gestures.forEach { view?.removeGestureRecognizer($0) }
    view = nil
  }
  
  @objc private func viewGestured(_ gesture: UIGestureRecognizer) {
    guard let view = view else { return }
    let loc = gesture.location(in: view)
    
    switch gesture.state {
    case .began, .changed:
      movedPublisher.send(loc)
    case .ended:
      endedPublisher.send(loc)
    default:
      break
    }
  }
}

public extension MultiGesture {
  static var slide: MultiGesture {
    .init(gestures: [
      UITapGestureRecognizer(),
      PanGestureRecognizer(direction: .horizontal)
    ])
  }
}

public class PanGestureRecognizer: UIPanGestureRecognizer {
  public struct Direction {
    public typealias Velocity = CGPoint
    public let isInDirection: (Velocity) -> Bool
    
    public static let horizontal: Self = .init { vel in
      abs(vel.x) > abs(vel.y)
    }
    
    public static let vertical: Self = .init { vel in
      abs(vel.y) > abs(vel.x)
    }
  }
  
  public let direction: Direction
  
  public init(direction: Direction) {
    self.direction = direction
    super.init(target: nil, action: nil)
    //super.init(target: target, action: action)
  }
  
  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    
    if state == .began {
      let vel = velocity(in: view)
      if !direction.isInDirection(vel) { state = .cancelled }
    }
  }
}
