import UIKit
import Combine

public typealias ScrollIndex = (row: Int, col: Int)

open class ScrollViewController: CombineViewController {
  private var viewControllers: [[UIViewController?]]
  
  public let indexPublisher: CurrentValueSubject<ScrollIndex, Never>
  public var viewControllerPublisher: AnyPublisher<UIViewController?, Never> {
    indexPublisher.map { index in
      self.viewControllers[index.row][index.col]
    }.eraseToAnyPublisher()
  }
  public let scrollPublisher: CurrentValueSubject<(row: CGFloat, col: CGFloat), Never>
  public let isScrollingPublisher = CurrentValueSubject<Bool, Never>(false)
  public var index: ScrollIndex { indexPublisher.value }
  //var isScrolling = false
  //private var displayLink: CADisplayLink!
  
//  @objc private func displayTick() {
//    print(scrollView.contentOffset)
//    //layer.presentation()?.forKey
//  }
  
  public private(set) lazy var scrollView = AutoScrollView(viewControllers: viewControllers, startingIndex: index) ~~ {
    $0.isPagingEnabled = true
    $0.isDirectionalLockEnabled = true
    $0.showsHorizontalScrollIndicator = false
    $0.showsVerticalScrollIndicator = false
    $0.bounces = false
    $0.contentInsetAdjustmentBehavior = .never
    $0.contentInset = .zero
    $0.scrollIndicatorInsets = .zero
    $0.scrollsToTop = false
    
    $0.delegate = self
  }
  
  public var scrollHeight: CGFloat { return scrollView.frame.height }
  public var scrollWidth: CGFloat { return scrollView.frame.width }
  
  public init(viewControllers: [[UIViewController?]], startIndex: (Int,Int)) {
    self.viewControllers = viewControllers
    self.indexPublisher = .init(startIndex)
    self.scrollPublisher = .init((row: CGFloat(startIndex.0), col: CGFloat(startIndex.1)))
    super.init()
//    displayLink = CADisplayLink(target: self, selector: #selector(displayTick)) ~~ {
//      $0.add(to: .current, forMode: .default)
//    }
    setupViewControllers()
  }
  
  private func setupViewControllers() {
    scrollView.forAllViewControllers { vc, row, col in addChild(vc) }
    view.addSubview(scrollView)
    scrollView.forAllViewControllers { vc, row, col in vc.didMove(toParent: self) }
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func isValidOffset(newOffset: CGPoint) -> Bool {
    let row = index.row
    let col = index.col
    
    let pageToLeft = Int(newOffset.x/scrollWidth)
    let pageToRight = Int(ceil(newOffset.x/scrollWidth + 1.0))-1
    let pageAbove = Int(newOffset.y/scrollHeight)
    let pageBelow = Int(ceil(newOffset.y/scrollHeight + 1.0))-1
    
    guard let left = viewControllers[row][safe: pageToLeft], left != nil else { return false }
    guard let right = viewControllers[row][safe: pageToRight], right != nil else { return false }
    guard let above = viewControllers[safe: pageAbove]?[col] else { return false }
    guard let below = viewControllers[safe: pageBelow]?[col] else { return false }
    
    let isOnValidTrack = (left == right) || (above == below)
    return isOnValidTrack
  }
}

extension ScrollViewController: UIScrollViewDelegate {
  private func updateIndex(_ scrollView: UIScrollView) {
    let newIndex = (
      row: Int(scrollView.contentOffset.y / scrollHeight),
      col: Int(scrollView.contentOffset.x / scrollWidth)
    )
    indexPublisher.send(newIndex)
  }
  
  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    updateIndex(scrollView)
    isScrollingPublisher.send(false)
    //isScrolling = false
  }
  
  public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    updateIndex(scrollView)
    //isScrolling = false
    isScrollingPublisher.send(false)
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    //defer {
    let page = (
      row: scrollView.contentOffset.y / scrollHeight,
      col: scrollView.contentOffset.x / scrollWidth
    )
    //print(page)
    scrollPublisher.send(page)
    //}
    if !isValidOffset(newOffset: scrollView.contentOffset) {
      scrollView.contentOffset = CGPoint(
        x: CGFloat(index.col) * scrollWidth,
        y: CGFloat(index.row) * scrollHeight
      )
      return
    }
  }
  
  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    guard !decelerate else { return }
    //isScrolling = false
    isScrollingPublisher.send(false)
  }
  
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    //isScrolling = true
    isScrollingPublisher.send(true)
  }
}

public extension ScrollViewController {
  func scrollTo(row: Int) {
    guard viewControllers.indices.contains(row), row != index.row else { return }
    let newOffset = CGPoint(x: CGFloat(self.index.col)*scrollWidth, y: CGFloat(row)*scrollHeight)
    scrollView.autoScroll(to: newOffset, duration: Theme.shared.animation.time)
  }
  
  func scrollTo(col: Int) {
    guard viewControllers[0].indices.contains(col), col != index.col else { return }
    let newOffset = CGPoint(x: CGFloat(col)*scrollWidth, y: CGFloat(self.index.row)*scrollHeight)
    scrollView.autoScroll(to: newOffset, duration: Theme.shared.animation.time)
  }
}

public class AutoScrollView: UIScrollView {
  private let viewControllers: [[UIViewController?]]
  private var _shouldRecognizeSimultaneously: (UIGestureRecognizer, UIGestureRecognizer) -> Bool = { _, _ in false }
  
  public init(viewControllers: [[UIViewController?]], startingIndex: ScrollIndex) {
    self.viewControllers = viewControllers
    super.init(frame: .zero)
    forAllViewControllers { vc, row, col in addSubview(vc.view) }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func forAllViewControllers(closure: (UIViewController, Int, Int) -> Void) {
    for row in 0..<viewControllers.count {
      for col in 0..<viewControllers[row].count {
        guard let vc = viewControllers[row][col] else { break }
        closure(vc, row, col)
      }
    }
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    let scrollHeight = frame.height
    let scrollWidth = frame.width
    
    forAllViewControllers { vc, row, col in
      vc.view.frame.size.width = scrollWidth
      vc.view.frame.size.height = scrollHeight
      vc.view.frame.origin.x = CGFloat(col) * scrollWidth
      vc.view.frame.origin.y = CGFloat(row) * scrollHeight
    }

    contentSize = CGSize(
      width: scrollWidth * CGFloat(viewControllers[0].count),
      height: scrollHeight * CGFloat(viewControllers.count)
    )
  }
  
  public func autoScroll(to offset: CGPoint, duration: TimeInterval) {
    delegate?.scrollViewWillBeginDragging?(self)
    UIView.animate(
      withDuration: Theme.shared.animation.time,
      //delay: 0,
      //options: [.allowUserInteraction],
      animations: {
        self.contentOffset = offset
      },
      completion: { _ in
        self.delegate?.scrollViewDidEndDecelerating?(self)
      }
    )
  }
}

extension AutoScrollView: UIGestureRecognizerDelegate {
  public func shouldRecognizeSimultaneously(_ closure: @escaping (UIGestureRecognizer, UIGestureRecognizer) -> Bool) {
    _shouldRecognizeSimultaneously = closure
  }
  
  public func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    _shouldRecognizeSimultaneously(gestureRecognizer, otherGestureRecognizer)
//    if let view = otherGestureRecognizer.view as? UIScrollView {
//      // TODO
//      return view.contentOffset.y <= 0 && contentOffset.y > 0
//         //|| view.contentOffset.x <= 0 && contentOffset.x > 0
//    }
//    return false
  }
}

//class NestedScrollView: AutoScrollView, UIGestureRecognizerDelegate {
//  func gestureRecognizer(
//    _ gestureRecognizer: UIGestureRecognizer,
//    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
//  ) -> Bool {
//    if let view = otherGestureRecognizer.view as? SlideCollectionView {
//      return view.contentOffset.y <= 0 && !view.selectionEnabled
//    }
//    return false
//  }
//}

//protocol SlideCellProtocol {
//  var tapped: Bool { get set }
//  func toggleSelection()
//}
//
//class SlideCollectionView: UICollectionView {
//  var selectedIndeces = Set<Int>()
//  private var lastSelectedIndex: Int?
//  var selectionEnabled = false
//
//  private lazy var slideGesture: SlideGesture = {
//    let slide = SlideGesture(direction: .horizontal)
//    slide.delegate = self
//    return slide
//  }()
//
//  private let limiter: ((Int) -> Bool)?
//  private let selectionCallback: ((Int) -> Void)?
//
//  init(
//    frame: CGRect,
//    collectionViewLayout layout: UICollectionViewLayout,
//    limiter: ((Int) -> Bool)? = nil,
//    selectionCallback: ((Int) -> Void)? = nil
//  ) {
//    self.selectionCallback = selectionCallback
//    self.limiter = limiter
//    super.init(frame: frame, collectionViewLayout: layout)
//    selectionCallback?(0)
//  }
//
//  required init?(coder aDecoder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//}
//
//extension SlideCollectionView {
//  func enableSelection() {
//    selectionEnabled = true
//
//    slideGesture.addTo(view: self)
//  }
//
//  func disableSelection() {
//    selectionEnabled = false
//
//    slideGesture.remove()
//
//    deselectAllCells()
//    clearSelected()
//  }
//}
//
//extension SlideCollectionView {
//  private func selectIndexFor(location: CGPoint) {
//    guard let currentIndexPath = indexPathForItem(at: location),
//          let cell = cellForItem(at: currentIndexPath) as? SlideCellProtocol
//    else { return lastSelectedIndex = nil }
//    let currentIndex = currentIndexPath.row
//    if lastSelectedIndex != currentIndex {
//      if !cell.tapped {
//        if let limiter = limiter, limiter(selectedIndeces.count) { return }
//        selectedIndeces.insert(currentIndex)
//      } else {
//        selectedIndeces.remove(currentIndex)
//      }
//      UIImpactFeedbackGenerator(style: .light).impactOccurred()
//      selectionCallback?(selectedIndeces.count)
//      cell.toggleSelection()
//      lastSelectedIndex = currentIndexPath.row
//    }
//  }
//
//  private func deselectAllCells() {
//    for cell in visibleCells {
//      if let slideCell = cell as? SlideCellProtocol, slideCell.tapped {
//        slideCell.toggleSelection()
//      }
//    }
//  }
//
//  private func clearSelected() {
//    selectedIndeces = []
//    selectionCallback?(selectedIndeces.count)
//  }
//}
//
//extension SlideCollectionView: SlideGestureDelegate {
//  func moved(to location: CGPoint) {
//    selectIndexFor(location: location)
//  }
//
//  func ended(at location: CGPoint) {
//    selectIndexFor(location: location)
//    lastSelectedIndex = nil
//  }
//}
//
//extension SlideCollectionView {
//  override func reloadData() {
//    if selectionEnabled {
//      disableSelection()
//      enableSelection()
//    }
//    super.reloadData()
//  }
//}

//@objc protocol SlideGestureDelegate: class {
//  @objc func moved(to location: CGPoint)
//  @objc func ended(at location: CGPoint)
//}

//class SlideGesture {
//  private var tapGesture: UITapGestureRecognizer?
//  private var panGesture: PanDirectionGestureRecognizer?
//  private var longPressGesture: UILongPressGestureRecognizer?
//
//  weak var delegate: SlideGestureDelegate?
//  weak var view: UIView?
//
//  var panDirection: PanDirection
//  var selectsImmediately: Bool
//
//  init(direction: PanDirection, selectsImmediately: Bool = false) {
//    self.panDirection = direction
//    self.selectsImmediately = selectsImmediately
//  }
//
//  func addTo(view: UIView) {
//    self.view = view
//
//    if selectsImmediately {
//      longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(viewGestured(_:)))
//      longPressGesture!.minimumPressDuration = 0.0
//      view.addGestureRecognizer(longPressGesture!)
//    } else {
//      panGesture = PanDirectionGestureRecognizer(direction: panDirection, target: self, action: #selector(viewGestured(_:)))
//      tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewGestured(_:)))
//
//      view.addGestureRecognizer(tapGesture!)
//      view.addGestureRecognizer(panGesture!)
//    }
//  }
//
//  func remove() {
//    if let tapGesture = tapGesture {
//      view?.removeGestureRecognizer(tapGesture)
//    }
//
//    if let panGesture = panGesture {
//      view?.removeGestureRecognizer(panGesture)
//    }
//
//    view = nil
//  }
//
//  @objc private func viewGestured(_ gesture: UIGestureRecognizer) {
//    guard let view = view else { return }
//    let loc = gesture.location(in: view)
//
//    switch gesture.state {
//    case .began, .changed:
//      delegate?.moved(to: loc)
//    case .ended:
//      delegate?.ended(at: loc)
//    default:
//      break
//    }
//  }
//}

//enum PanDirection {
//  case vertical
//  case horizontal
//}



public extension UIViewController {
  func add(_ child: UIViewController, to view: UIView) {
    addChild(child)
    view.addSubview(child.view)
    child.didMove(toParent: self)
  }
  
  func remove() {
    guard parent != nil else { return }
    willMove(toParent: nil)
    removeFromParent()
    view.removeFromSuperview()
  }
}
