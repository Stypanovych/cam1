import Combine
import RevenueCat
import DazeFoundation

public struct ProductStore {
  public let purchases: () -> AnyPublisher<Set<Purchase>, GenericError>
  public let restorePurchases: () -> AnyPublisher<Set<Purchase>, GenericError>
  public let product: () -> AnyPublisher<Product, GenericError>
  public let purchase: (Product, Payment) -> AnyPublisher<Purchase, GenericError>
}

extension Purchases {
  func checkTrialOrIntroDiscountEligibility(product: StoreProduct) -> AnyPublisher<IntroEligibilityStatus, Never> {
    return Future.deferred { promise in
      self.checkTrialOrIntroDiscountEligibility(product: product) { status in
        promise(.success(status))
      }
    }
  }
  
  func getOfferings() -> AnyPublisher<Offerings, Error> {
    return Future.deferred { promise in
      self.getOfferings { offerings, error in
        if let offerings = offerings {
          promise(.success(offerings))
        } else {
          promise(.failure(error ?? GenericError("unknown")))
        }
      }
    }
  }
}

extension Payment {
  static func from(storeProduct: StoreProduct, status: IntroEligibilityStatus) -> Self {
    return .init(
      id: Payment.ID(rawValue: storeProduct.productIdentifier),
      trialDescription: (status == .eligible) ? storeProduct.introductoryDiscount?.subscriptionPeriod.title : nil,
      costDescription: {
        let durationString = (storeProduct.subscriptionPeriod?.denominatorTitle)
          .map { "/ \($0)" }
          ?? "one-time"
        return storeProduct.localizedPriceString + " " + durationString
      }()
    )
  }
}

extension ProductStore {
  // include Keychain_Legacy.purchasedPremium
  public static func revenuecatWithLegacy() -> Self {
    let productStore = revenuecat()
    return .init(
      purchases: {
        guard !Keychain_Legacy.shared.purchasedPremium else {
          let premium = Purchase(product: .premium, payment: .init(rawValue: "premium_prod_1"))
          return Just([premium]).setFailureType(to: GenericError.self).eraseToAnyPublisher()
        }
        return productStore.purchases()
      },
      restorePurchases: productStore.restorePurchases,
      product: productStore.product,
      purchase: productStore.purchase
    )
  }
  
  public static func revenuecat() -> Self {
    let purchases = Purchases.configure(withAPIKey: "appl_fnufYJefSPDpLuxBVCCvEnYuWWn")
    
    var payments: Dictionary<Payment.ID, StoreProduct> = [:]
    
    func getPurchases(using closure: @escaping (@escaping (CustomerInfo?, Error?) -> Void) -> Void) -> AnyPublisher<Set<Purchase>, GenericError> {
      return Future.deferred { promise in
        closure { customerInfo, error in
          guard let customerInfo = customerInfo
          else { return promise(.failure(.generic(error?.localizedDescription ?? ""))) }
          let purchases = customerInfo.entitlements.all.compactMap { (id, info) -> Purchase? in
            guard info.isActive else { return nil }
            return Purchase(
              product: Product.ID(rawValue: id),
              payment: Payment.ID(rawValue: info.productIdentifier)
            )
          }
          promise(.success(Set(purchases)))
        }
      }
    }
    
    func product() -> AnyPublisher<Product, GenericError> {
      return purchases.getOfferings()
        .mapError { GenericError($0.localizedDescription) }
        .flatMap { (offerings: Offerings) -> AnyPublisher<Product, GenericError> in
          guard let offering = offerings.current
          else { return .fail(.generic("no current offerings"))}
          return Publishers.Sequence(sequence: offering.availablePackages)
            .flatMap(maxPublishers: .max(1)) { (package) -> AnyPublisher<(StoreProduct, IntroEligibilityStatus), GenericError> in
              return purchases
                .checkTrialOrIntroDiscountEligibility(product: package.storeProduct)
                .setFailureType(to: GenericError.self)
                .map { (package.storeProduct, $0) }
                .eraseToAnyPublisher()
            }
            .collect()
            .receive(on: DispatchQueue.main)
            .map { productStatuses in
              return productStatuses.map { (product, status) -> Payment in
                payments[Payment.ID(rawValue: product.productIdentifier)] = product
                return .from(storeProduct: product, status: status)
              }
            }
            .map {
              Product(
                id: .premium,
                acceptedPayments: $0
              )
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func purchase(product: Product, payment: Payment) -> AnyPublisher<Purchase, GenericError> {
      guard
        product.acceptedPayments.contains(payment),
        let storeProduct = payments[payment.id]
      else { return .fail(.generic("payment not accepted for product")) }
      return Future.deferred { promise in
        purchases.purchase(product: storeProduct) { storeTransaction, customerInfo, error, userCancelled in
          if
            let customerInfo = customerInfo?.entitlements[product.id.rawValue],
            customerInfo.isActive
          {
            let purchase = Purchase(
              product: product.id,
              payment: payment.id
            )
            promise(.success(purchase))
          } else if let error = error {
            promise(.failure(.generic(error.localizedDescription)))
          }
        }
      }
    }
    
    return .init(
      purchases: { return getPurchases(using: purchases.getCustomerInfo) },
      restorePurchases: { return getPurchases(using: purchases.restorePurchases) },
      product: product,
      purchase: purchase
    )
  }
}

import Foundation

extension SubscriptionPeriod.Unit {
  var calendarUnit: NSCalendar.Unit {
    switch self {
    case .day: return .day
    case .week: return .weekOfMonth
    case .month: return .month
    case .year: return .year
    }
  }
  
  var title: String {
    switch self {
    case .day: return "day"
    case .week: return "week"
    case .month: return "month"
    case .year: return "year"
    }
  }
}

extension SubscriptionPeriod {
  var denominatorTitle: String {
    format(unit: unit.calendarUnit, numberOfUnits: value) ?? ""
  }
  
  var title: String {
    "\(value)-\(unit.title)"
  }
  
  private var componentFormatter: DateComponentsFormatter {
    let formatter = DateComponentsFormatter()
    formatter.maximumUnitCount = 1
    formatter.unitsStyle = .full
    formatter.zeroFormattingBehavior = .dropAll
    return formatter
  }

  private func format(unit: NSCalendar.Unit, numberOfUnits: Int) -> String? {
    let calendar = Calendar.current
    
    var dateComponents = DateComponents()
    dateComponents.calendar = calendar
    componentFormatter.allowedUnits = [unit]

    switch unit {
    case .day: dateComponents.setValue(numberOfUnits, for: .day)
    case .weekOfMonth: dateComponents.setValue(numberOfUnits, for: .weekOfMonth)
    case .month: dateComponents.setValue(numberOfUnits, for: .month)
    case .year: dateComponents.setValue(numberOfUnits, for: .year)
    default: return nil
    }
    let string = componentFormatter.string(from: dateComponents)
    return (numberOfUnits == 1)
      ? string?.replacingOccurrences(of: "1", with: "").trimmingCharacters(in: .whitespaces)
      : string
  }
}

extension Calendar {
  static var localized: Calendar {
    let prefLanguage = Locale.preferredLanguages.first!
    var calendar = Calendar.current
    calendar.locale = Locale(identifier: prefLanguage)
    return calendar
  }
}

public struct Purchase: Hashable {
  public let product: Product.ID
  public let payment: Payment.ID
  
  public init(
    product: Product.ID,
    payment: Payment.ID
  ) {
    self.product = product
    self.payment = payment
  }
}

// revenuecat entitlement, accepted payments represent offerings
public struct Product: Hashable {
  public let id: ID
  public let acceptedPayments: [Payment]
  
  public struct ID: Hashable {
    let rawValue: String
    
    static var premium: Self { .init(rawValue: "premium") }
  }
}

// referred to as 'Product' with IAP
public struct Payment: Hashable {
  public let id: ID
  public let trialDescription: String?
  public let costDescription: String
  
  public struct ID: Hashable {
    let rawValue: String
  }
}

//public extension Product {
//  static let premium: Self = .init(
//    id: "premium",
//    acceptedPayments: [.premiumOneTime, .premiumMonthly, .premiumYearly]
//  )
//}
//
//extension StoreProduct {
//  var payment: Payment {
//    return .init(
//      id: productIdentifier,
//      costDescription: localizedPriceString
//    )
//  }
//}
public extension Product {
  static func premium(payments: [Payment]) -> Self { .init(id: .premium, acceptedPayments: payments) }
}

#if DEBUG
public extension Payment {
  static let mockPremiumOneTime: Self = .init(
    id: .mockPremiumOneTime,
    trialDescription: nil,
    costDescription: "$19.99 one-time"
  )
  static let mockPremiumMonthly: Self = .init(
    id: .mockPremiumMonthly,
    trialDescription: "3-day",
    costDescription: "$2.99 / month"
  )
  static let mockPremiumYearly: Self = .init(
    id: .mockPremiumYearly,
    trialDescription: "7-day",
    costDescription: "$12.99 / year"
  )
}

public extension Payment.ID {
  static let mockPremiumOneTime: Self = .init(rawValue: "premiumOneTime")
  static let mockPremiumMonthly: Self = .init(rawValue: "premiumMonthly")
  static let mockPremiumYearly: Self = .init(rawValue: "premiumYearly")
}

public extension Product {
  static let mockPremium: Self = .init(
    id: .premium,
    acceptedPayments: [.mockPremiumMonthly, .mockPremiumYearly, .mockPremiumOneTime]
  )
}

public extension Purchase {
  static func mockPremium(payment: Payment) -> Self { .init(product: .premium, payment: payment.id) }
}

public extension ProductStore {
  static func mock(
    initialPurchases: Result<Set<Purchase>, GenericError>,
    restoredPurchases: Result<Set<Purchase>, GenericError>,
    acceptedPayments: [Payment] = [.mockPremiumMonthly, .mockPremiumYearly, .mockPremiumOneTime],
    purchase: Result<Purchase, GenericError>
  ) -> Self {
    var purchases: Set<Purchase> = (try? initialPurchases.get()) ?? []
    return .init(
      purchases: { Just(purchases).setFailureType(to: GenericError.self).eraseToAnyPublisher() },
      restorePurchases: {
        purchases = purchases.union((try? initialPurchases.get()) ?? [])
        return restoredPurchases.publisher.eraseToAnyPublisher()
      },
      product: { Just(.premium(payments: acceptedPayments)).setFailureType(to: GenericError.self).eraseToAnyPublisher() },
      purchase: { product, payment in
        _ = (try? purchase.get()).map { purchases.insert($0) }
        return purchase.publisher.eraseToAnyPublisher()
      }
    )
  }
  
  static func purchaseSuccessMock() -> Self {
    let premium: Purchase = .mockPremium(payment: .mockPremiumMonthly)
    return mock(
      initialPurchases: .success([]),
      restoredPurchases: .success([]),
      purchase: .success(premium)
    )
  }
  
  static func alreadyPurchasedMock() -> Self {
    let premium: Set<Purchase> = [.mockPremium(payment: .mockPremiumMonthly)]
    return mock(
      initialPurchases: .success(premium),
      restoredPurchases: .success(premium),
      purchase: .failure(.generic("alreadyPurchased"))
    )
  }
  
  static func noAcceptedPaymentsMock() -> Self {
    mock(
      initialPurchases: .success([]),
      restoredPurchases: .success([.mockPremium(payment: .mockPremiumMonthly)]),
      acceptedPayments: [],
      purchase: .failure(.generic("no accepted payments"))
    )
  }
  
  static func restoreMock() -> Self {
    mock(
      initialPurchases: .success([]),
      restoredPurchases: .success([.mockPremium(payment: .mockPremiumMonthly)]),
      purchase: .failure(.generic("already purchased"))
    )
  }
}
#endif
