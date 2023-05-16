import UIKit
import SwiftUI
import Combine
import Engine

struct PanelContainerView<Containee: View>: View {
  let containee: Containee
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    //GeometryReader { proxy in
      VStack {
        Spacer()
        containee
        Spacer()
      }
      .padding(theme.margins)
    //}
    .background(theme.color.dark.swiftui)
    .cornerRadius(theme.margins)
  }
}

struct GlowPanelView: View {
  let threshold: Binding<CGFloat>
  let radius: Binding<CGFloat>
  let intensity: Binding<CGFloat>
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    HStack {
      Margin()
      VStack {
        TitledSlider(title: "sensitivity", binding: threshold)
        TitledSlider(title: "radius", binding: radius)
        TitledSlider(title: "intensity", binding: intensity)
      }
      Margin()
    }
  }
}

struct ChromaPanelView: View {
  let intensity: Binding<CGFloat>
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    HStack {
      Margin()
      VStack {
        TitledSlider(title: "intensity", binding: intensity)
      }
      Margin()
    }
  }
}

struct BlurPanelView: View {
  let binding: Binding<CGFloat>
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    HStack {
      Margin()
      VStack {
        TitledSlider(title: "intensity", binding: binding)
      }
      Margin()
    }
  }
}

struct TitledSlider: View {
  let title: String
  let binding: Binding<CGFloat>
  //@State private var lastValue
  //@State private var sliderSize: CGSize = .zero
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    HStack {
      Text(title.uppercased())
        .foregroundColor(theme.light.swiftui)
        .font(theme.main.mid.black.uiFont.swiftui)
        .onTapGesture {
          switch binding.wrappedValue {
          case 0: binding.wrappedValue = 1
          case 1: binding.wrappedValue = 0
          default: binding.wrappedValue = round(binding.wrappedValue)
          }
        }
      Spacer()
      Slider(value: binding)
//        .readSize { size in
//          sliderSize = size
//        }
        .accentColor(theme.pink.swiftui)
        .frame(width: theme.unit * 20)
//        .simultaneousGesture(
//          DragGesture(minimumDistance: 0)
//            .onChanged { _ in
//              print("dragini")
//            }
//            .onEnded { _ in
//            }
//        )
    }
  }
}

struct TitledSwitch: View {
  let title: String
  let binding: Binding<Bool>
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    HStack {
      Text(title.uppercased())
        .foregroundColor(theme.light.swiftui)
        .font(theme.main.mid.black.uiFont.swiftui)
      Spacer().frame(width: theme.margins)
      if #available(iOS 14.0, *) {
        Toggle("", isOn: binding)
          .toggleStyle(SwitchToggleStyle(tint: theme.pink.swiftui))
      } else {
        Toggle("", isOn: binding)
      }
    }
  }
}


extension View {
  func panelContainer() -> some View {
    PanelContainerView(containee: self)
  }
}

extension View {
  func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
    background(
      GeometryReader { geometryProxy in
        Color.clear
          .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
      }
    )
    .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
  }
}

private struct SizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

//struct PanelPreviews: PreviewProvider {
//  static var previews: some View {
//    var slidevalue: CGFloat = 0
//    GlowPanelView(binding: .init(get: { slidevalue }, set: { slidevalue = $0 }))
//      .panelContainer()
//      .environmentObject(Theme.shared)
//  }
//}
