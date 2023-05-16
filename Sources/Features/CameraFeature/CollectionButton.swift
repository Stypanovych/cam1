import Engine
import UIKit

class CollectionButton: UIButton {
  private let squares = 2
  
  private var squareViews = [[UIView]]()
  private var squareContainer = UIView() ~~ {
    $0.isUserInteractionEnabled = false
  }
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: frame.height, height: frame.height)
  }
  
  init(color: UIColor = .dazecam.light) {
    super.init(frame: CGRect())
    
    for _ in 0 ..< squares {
      var row = [UIView]()
      for _ in 0 ..< squares {
        let square = UIView()
        square.backgroundColor = color
        row.append(square)
        squareContainer.addSubview(square)
      }
      squareViews.append(row)
    }
    
    addSubview(squareContainer)
    squareContainer.snp.makeConstraints { make in
      make.top.bottom.centerX.equalToSuperview()
      make.width.equalTo(squareContainer.snp.height)
    }
  }
  
  override func layoutSubviews() {
    squareContainer.layoutIfNeeded()
    
    let spacing = squareContainer.frame.height / CGFloat(squares) / 5
    let squareSide = (squareContainer.frame.height - CGFloat(squares - 1) * spacing) / CGFloat(squares)
    
    for i in 0 ..< squares {
      for j in 0 ..< squares {
        let square = squareViews[j][i]
        let frame = CGRect(
          x: CGFloat(i) * (squareSide + spacing),
          y: CGFloat(j) * (squareSide + spacing),
          width: squareSide,
          height: squareSide
        )
        square.frame = frame
        square.layer.cornerRadius = squareSide / 15
      }
    }
    invalidateIntrinsicContentSize()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
