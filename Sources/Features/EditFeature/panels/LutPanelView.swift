import UIKit
import SwiftUI
import Engine
import ImageProcessor
import Combine

class TitledImageView: UIView {
  init() {
    super.init(frame: .zero)
    addSubview(imageView)
    addSubview(label)
    
    imageView.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.width.equalTo(imageView.snp.height)
    }
    
    label.snp.makeConstraints { make in
      make.bottom.equalToSuperview()
      make.centerX.equalToSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private(set) lazy var label = UILabel() ~~ {
    $0.font = .dazecam.main.small.heavy.uiFont
    $0.textColor = .dazecam.light
  }
  
  private(set) lazy var imageView = UIImageView() ~~ {
    $0.clipsToBounds = true
    $0.contentMode = .scaleAspectFill
    $0.layer.cornerCurve = .continuous
    $0.layer.cornerRadius = Theme.shared.unit
  }
}

extension Cell.Configuration where View == TitledImageView {
  static func configuration(
    title: String,
    _ imageFactory: @escaping () -> UIImage,
    queue: DispatchQueue
  ) -> Cell<TitledImageView>.Configuration {
    return .init(
      createView: {
        TitledImageView()
      },
      configure: { view in
        view.alpha = 0
        view.label.text = title
        return Future<UIImage, Never>.deferred { promise in
          promise(.success(imageFactory()))
        }
        .subscribe(on: queue)
        .receive(on: DispatchQueue.main)
        .animate(0.15) { uiimage in
          view.imageView.image = uiimage
          view.alpha = 1
        }
        .sink { _ in }
      },
      prepareForReuse: { view in
        view.label.text = nil
        view.imageView.image = nil
      }
    )
  }
}

struct FilterPanelView<Content: View>: View {
  let binding: Binding<CGFloat>
  let content: Content
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    VStack {
      Spacer()
      content.frame(height: theme.unit * 8)
      Margin()
      HStack {
        Margin()
        TitledSlider(title: "intensity", binding: binding)
        Margin()
      }
      Spacer()
    }
  }
}

