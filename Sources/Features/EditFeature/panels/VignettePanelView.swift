import SwiftUI
import Engine

struct VignettePanelView: View {
  //let centerX: Binding<CGFloat>
  //let centerY: Binding<CGFloat>
  let intensity: Binding<CGFloat>
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    HStack {
      Margin()
      VStack {
        //TitledSlider(title: "centerX", binding: centerX)
        //TitledSlider(title: "centerY", binding: centerY)
        TitledSlider(title: "intensity", binding: intensity)
      }
      Margin()
    }
  }
}
