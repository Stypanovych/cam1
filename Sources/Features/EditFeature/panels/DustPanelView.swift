import SwiftUI
import Engine

struct DustPanelView: View {
  let particles: Binding<CGFloat>
  let hairs: Binding<CGFloat>
  let opacity: Binding<CGFloat>
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    HStack {
      Margin()
      VStack {
        Spacer()
        TitledSlider(title: "particles", binding: particles)
        Spacer().frame(height: 20)
        TitledSlider(title: "hairs", binding: hairs)
        Spacer().frame(height: 20)
        TitledSlider(title: "intensity", binding: opacity)
        Spacer()
      }
      Margin()
    }
  }
}
