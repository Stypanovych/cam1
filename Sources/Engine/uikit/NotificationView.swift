import SwiftUI

public struct NotificationView: View {
  public let notification: Engine.Notification
  
  @EnvironmentObject private var theme: Theme
  
  public init(notification: Engine.Notification) {
    self.notification = notification
  }
  
  public var body: some View {
    Text(notification.message)
      .font(theme.main.small.black.uiFont.swiftui)
      .padding(theme.unit)
      .frame(maxWidth: .infinity)
      .background(theme.pink.swiftui)
      .foregroundColor(theme.dark.swiftui)
  }
}
