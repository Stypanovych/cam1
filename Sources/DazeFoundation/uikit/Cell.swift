import UIKit
import SnapKit
import Combine

public class Cell<View: UIView>: UICollectionViewCell {
  public struct Configuration {
    public let createView: () -> View
    public let configure: (View) -> AnyCancellable?
    public let prepareForReuse: (View) -> Void
    
    public init(
      createView: @escaping () -> View,
      configure: @escaping (View) -> AnyCancellable?,
      prepareForReuse: @escaping (View) -> Void
    ) {
      self.createView = createView
      self.configure = configure
      self.prepareForReuse = prepareForReuse
    }
  }
  
  private struct ViewState {
    var view: View
    var configuration: Configuration
  }
  
  private var viewState: ViewState?
  private var cancellable: AnyCancellable?
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public func configure(with configuration: Configuration) {
    defer {
      cancellable = configuration.configure(viewState!.view)
    }
    guard viewState == nil else {
      viewState?.configuration = configuration
      return
    }
    let view = configuration.createView()
    contentView.addSubview(view)
    view.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    viewState = .init(view: view, configuration: configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    cancellable = nil
    guard let viewState = viewState else { return }
    viewState.configuration.prepareForReuse(viewState.view)
  }
}
