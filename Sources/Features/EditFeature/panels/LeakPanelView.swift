import SwiftUI
import Engine

struct LeakPanelView<Content: View>: View {
  let binding: Binding<CGFloat>
  let content: Content
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    VStack {
      Spacer()
      content.frame(height: 80)
      Spacer().frame(height: 20)
      HStack {
        Margin()
        TitledSlider(title: "intensity", binding: binding)
        Margin()
      }
      Spacer()
    }
  }
}
