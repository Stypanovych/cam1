import Foundation

public struct Notification: Hashable {
  public let message: String
  public let id: UUID = .init()
  
  public init(message: String) {
    self.message = message
  }
}

public extension Notification {
  static let saveFailure: Self = .init(message: "Save failed")
  static let tryAgain: Self = .init(message: "Save failed. Restart and try again")
  static let downloadSuccess: Self = .init(message: "Downloaded")
  static let downloadFailure: Self = .init(message: "Download failed")
}
