import SwiftUI
import Engine

struct DatePanelView<FontPicker: View>: View {
  let fontPicker: FontPicker
  let color: Binding<CGFloat>
  let dateVisible: Binding<Bool>
  let timeVisible: Binding<Bool>
  
  @EnvironmentObject var theme: Theme
  
  var body: some View {
    HStack {
      Margin()
      VStack {
        Spacer()
        fontPicker.frame(height: 20)
        Spacer()
        TitledSlider(title: "COLOR", binding: color)
        Spacer()
        TitledSwitch(title: "DATE", binding: dateVisible)
        Spacer()
        TitledSwitch(title: "TIME", binding: timeVisible)
        Spacer()
      }
      Margin()
    }
  }
}
