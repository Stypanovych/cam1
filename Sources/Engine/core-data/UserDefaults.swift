import KeychainAccess
import Foundation
import DazeFoundation
//func test() {
//  let persistentUser = Persistent<User>()
//    .assign(storage: .userDefaults, key: "shit", to: \.openedApp)
//    .assign(storage: .keychain, key: "fuck", to: \.askedForReview)
//
//  try! persistentUser.write(\.askedForReview, value: false)
//}

//extension Persisted {
//  static func migrateLegacy() -> Persisted {
//    let keychainLegacy = Keychain_Legacy()
//    let userDefaultsLegacy = UserDefaults_Legacy()
//    return Persisted() ~~ {
//      $0.purchasedPremium = keychainLegacy.purchasedPremium
//      $0.earlyAdopter = keychainLegacy.earlyAdopter
//      $0.user = .init(
//        openedApp: userDefaultsLegacy.userDidOpenApp,
//        askedForReview: userDefaultsLegacy.didAskForReview
//      )
//    }
//  }
//}

//class Keychain {
//  static let shared = Keychain()
//  private let keychain = Keychain()
//  
//  
//}

public class KeychainStorage {
  public static let shared = KeychainStorage()
  
  @Persist(.keychain, key: "importsCount", defaultValue: 0) public var importsCount: Int
}

public class Keychain_Legacy {
  public static let shared = Keychain_Legacy()
  private let keychain = Keychain()

  private var earlyAdopterKey = "earlyAdopter"
  private var earlyAdopter: Bool {
    return keychain[earlyAdopterKey] == "true"
  }
  
  private var purchasedPremiumKey = "purchasedPremium"
  var purchasedPremium: Bool {
    return earlyAdopter || keychain[purchasedPremiumKey] == "true"
  }
  
  public func reset() {
    keychain[purchasedPremiumKey] = "false"
    keychain[earlyAdopterKey] = "false"
  }
  
//  private var importedPhotosKey = "importedPhotos"
//  var importedPhotos: Int {
//    set(val) {
//      keychain[importedPhotosKey] = "\(val)"
//    }
//    get {
//      return Int(keychain[importedPhotosKey] ?? "\(0)") ?? 0
//    }
//  }
//
//  private var importLimitKey = "importLimit"
//  var importLimit: Int? {
//    set(val) {
//      guard let val = val else {
//        keychain[importLimitKey] = nil
//        return
//      }
//      keychain[importLimitKey] = "\(val)"
//    }
//    get {
//      guard let string = keychain[importLimitKey] else { return nil }
//      return Int(string)
//    }
//  }
}

class UserDefaults_Legacy {
  private let userDefaults = UserDefaults.standard
  //static let shared = UserDefaultsStorage()
  
  private let userDidOpenAppKey = "userDidOpenApp"
  var userDidOpenApp: Bool {
    set(val) {
      userDefaults.set(val, forKey: userDidOpenAppKey)
    }
    get {
      return userDefaults.bool(forKey: userDidOpenAppKey)
    }
  }
  
  private let didAskForReviewKey = "didAskForReview"
  var didAskForReview: Bool {
    set(val) {
      userDefaults.set(val, forKey: didAskForReviewKey)
    }
    get {
      return userDefaults.bool(forKey: didAskForReviewKey)
    }
  }
}

//class UserDefaultsStorage {
//    static let shared = UserDefaultsStorage()
//
//    private init() {  }
//
//    private let savedEditsCountKey = "savedEditsCount"
//    var savedEditsCount: Int {
//        set(val) {
//            userDefaults.set(val, forKey: savedEditsCountKey)
//        }
//        get {
//            return userDefaults.integer(forKey: savedEditsCountKey)
//        }
//    }
//
//    private let downloadedImagesCountKey = "downloadedImagesCount"
//    var downloadedImagesCount: Int {
//        set(val) {
//            userDefaults.set(val, forKey: downloadedImagesCountKey)
//        }
//        get {
//            return userDefaults.integer(forKey: downloadedImagesCountKey)
//        }
//    }
//
//    private let viewedThanksAlertKey = "viewedThanksAlert"
//    var viewedThanksAlert: Bool {
//        set(val) {
//            userDefaults.set(val, forKey: viewedThanksAlertKey)
//        }
//        get {
//            return userDefaults.bool(forKey: viewedThanksAlertKey)
//        }
//    }
//
//    private let userDidOpenAppKey = "userDidOpenApp"
//    var userDidOpenApp: Bool {
//        set(val) {
//            userDefaults.set(val, forKey: userDidOpenAppKey)
//        }
//        get {
//            return userDefaults.bool(forKey: userDidOpenAppKey)
//        }
//    }
//
//    private let didAskForReviewKey = "didAskForReview"
//    var didAskForReview: Bool {
//        set(val) {
//            userDefaults.set(val, forKey: didAskForReviewKey)
//        }
//        get {
//            return userDefaults.bool(forKey: didAskForReviewKey)
//        }
//    }
//
//    private let userDefaults = UserDefaults.standard
//}



//class KeychainStorage {
//
//    static let shared = KeychainStorage()
//
//    var earlyAdopter: Bool {
//        set(val) {
//            print("is early adopter " + (keychain[earlyAdopterKey] ?? "not set"))
//            //if keychain[earlyAdopterKey] == nil {
//                keychain[earlyAdopterKey] = (val ? "true" : "false")
//            //}
//        }
//        get {
//            return keychain[earlyAdopterKey] == "true"
//        }
//    }
//
//    var purchasedPremium: Bool {
//        set(val) {
//            keychain[purchasedPremiumKey] = (val ? "true" : "false")
//        }
//        get {
//            return earlyAdopter || keychain[purchasedPremiumKey] == "true"
//        }
//    }
//
//    var importedPhotos: Int {
//        set(val) {
//            keychain[importedPhotosKey] = "\(val)"
//        }
//        get {
//            return Int(keychain[importedPhotosKey] ?? "\(0)") ?? 0
//        }
//    }
//
//    var importLimit: Int? {
//        set(val) {
//            guard let val = val else {
//                keychain[importLimitKey] = nil
//                return
//            }
//            keychain[importLimitKey] = "\(val)"
//        }
//        get {
//            guard let string = keychain[importLimitKey] else { return nil }
//            return Int(string)
//        }
//    }
//
//    private var keychain = Keychain()
//    private var earlyAdopterKey = "earlyAdopter"
//    private var purchasedPremiumKey = "purchasedPremium"
//    private var importedPhotosKey = "importedPhotos"
//    private var importLimitKey = "importLimit"
//
//    private init() { }
//}

