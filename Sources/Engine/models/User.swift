import DazeFoundation
import Foundation
import ComposableArchitecture

public struct User: Equatable, DazeFoundation.Default {
  public var id: UUID
  public var openedApp: Bool
  public var viewedReviewPrompt: Bool
  public var importsCount: Int
  public var importLimit: Int
  public var images: IdentifiedArrayOf<FilteredImage>
  public var presets: IdentifiedArrayOf<Preset>
  public var purchases: Set<Purchase>
  
  public init(
    id: UUID,
    openedApp: Bool,
    viewedReviewPrompt: Bool,
    importsCount: Int,
    importLimit: Int,
    images: IdentifiedArrayOf<FilteredImage>,
    presets: IdentifiedArrayOf<Preset>,
    purchases: Set<Purchase>
  ) {
    self.id = id
    self.openedApp = openedApp
    self.viewedReviewPrompt = viewedReviewPrompt
    self.importsCount = importsCount
    self.importLimit = importLimit
    self.images = images
    self.presets = presets
    self.purchases = purchases
  }
  
  public static var `default`: Self {
    .init(
      id: .init(),
      openedApp: false,
      viewedReviewPrompt: false,
      importsCount: 0,
      importLimit: 3,
      images: [],
      presets: [],
      purchases: []
    )
  }
}

public extension User {
  func purchased(_ product: Product) -> Bool {
    purchases.map(\.product).contains(product.id)
  }
  
  var purchasedPremium: Bool {
    purchases.map(\.product).contains(.premium)
  }
  
  var importsLeft: Int? {
    guard !purchasedPremium else { return nil }
    return max(0, importLimit - importsCount)
  }
}
