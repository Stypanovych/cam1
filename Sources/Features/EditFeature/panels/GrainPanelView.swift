import SwiftUI
import Engine

struct GrainPanelView: View {
  let size: Binding<CGFloat>
  let opacity: Binding<CGFloat>
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    HStack {
      Margin()
      VStack {
        Spacer()
        TitledSlider(title: "size", binding: size)
        Margin()
        TitledSlider(title: "intensity", binding: opacity)
        Spacer()
      }
      Margin()
    }
  }
}
