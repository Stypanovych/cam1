import SwiftUI
import DazeFoundation

public struct DazeButtonStyle: ButtonStyle {
  @EnvironmentObject var theme: Theme
  
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(theme.main.large.heavy.uiFont.swiftui)
      .foregroundColor(theme.dark.swiftui)
  }
}

public struct Assets {
  public let x = Image("X")
  public let back = Image("Back")
  
  static let live = Assets()
}

public extension Image {
  static var dazecam: Assets { .live }
}

public struct DazeButton: View {
  let content: (Theme) -> AnyView
  let action: () -> Void
  @EnvironmentObject var theme: Theme
  
  public init(_ text: String, action: @escaping () -> Void) {
    self.content = { theme in
      AnyView(Text(text)
        .lineLimit(1)
        .fixedSize()
        .font(theme.main.large.black.uiFont.swiftui)
        .foregroundColor(theme.dark.swiftui)
      )
    }
    self.action = action
  }
  
  public init(_ text: String, color: Color, action: @escaping () -> Void) {
    self.content = { theme in
      AnyView(Text(text)
        .lineLimit(1)
        .fixedSize()
        .font(theme.main.large.black.uiFont.swiftui)
        .foregroundColor(color)
      )
    }
    self.action = action
  }
  
  public init(image: Image, action: @escaping () -> Void) {
    self.content = { _ in
      AnyView(
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          //.frame(height: 13)
      )
    }
    self.action = action
  }
  
  public var body: some View {
    content(theme)
      .onTap(
        began: {
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
        },
        ended: {
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          action()
        }
      )
  }
}

public extension View {
  func hapticTap(_ action: @escaping () -> Void) -> some View {
    onTap(
      began: {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
      },
      ended: {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        action()
      }
    )
  }
}

public struct Margin: View {
  let hMultiple: CGFloat
  let vMultiple: CGFloat
  @EnvironmentObject var theme: Theme
  
  private init(
    hMultiple: CGFloat = 1.0,
    vMultiple: CGFloat = 1.0
  ) {
    self.hMultiple = hMultiple
    self.vMultiple = vMultiple
  }
  
  public init(_ multiple: CGFloat = 1.0) {
    self.hMultiple = multiple
    self.vMultiple = multiple
  }
  
  public static func horizontal(_ multiple: CGFloat = 1.0) -> Self {
    .init(hMultiple: multiple, vMultiple: 0)
  }
  
  public static func vertical(_ multiple: CGFloat = 1.0) -> Self {
    .init(hMultiple: 0, vMultiple: multiple)
  }
  
  public var body: some View {
    Spacer().frame(width: hMultiple * theme.margins, height: vMultiple * theme.margins)
  }
}

extension View {
  /// A convenience method for applying `TouchDownUpEventModifier.`
  func onTap(
    began: @escaping () -> Void,
    ended: @escaping () -> Void
  ) -> some View {
    self.modifier(TouchDownUpEventModifier(pressed: {
      $0 ? began() : ended()
    }))
  }
}

struct TouchDownUpEventModifier: ViewModifier {
  /// Keep track of the current dragging state. To avoid using `onChange`, we won't use `GestureState`
  @State var dragged = false
  
  /// A closure to call when the dragging state changes.
  var pressed: (Bool) -> Void
  func body(content: Content) -> some View {
    content
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            if !dragged {
              dragged = true
              pressed(true)
            }
          }
          .onEnded { _ in
            dragged = false
            pressed(false)
          }
      )
  }
}

class AutoSizingHostingController<T: View> : UIHostingController<T> {
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.view.invalidateIntrinsicContentSize()
  }
}

public class HostingView<T: View>: UIView {
  public private(set) var hostingController: UIHostingController<T>

  public init(rootView: T, from viewController: UIViewController) {
    hostingController = AutoSizingHostingController(rootView: rootView)
    super.init(frame: .zero)
    
    viewController.addChild(hostingController)
    hostingController.didMove(toParent: viewController)
    
    backgroundColor = .clear
    hostingController.view.backgroundColor = backgroundColor
    addSubview(hostingController.view)
    hostingController.view.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

public extension View {
  func uiview(viewController: UIViewController) -> UIView {
    HostingView(rootView: self, from: viewController)
  }
}
