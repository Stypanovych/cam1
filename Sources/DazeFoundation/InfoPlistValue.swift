import Foundation

@propertyWrapper
public struct InfoPlistValue<T: LosslessStringConvertible> {
  private let key: String

  public init(_ key: String) {
    self.key = key
  }

  public var wrappedValue: T? {
    guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
      return nil
    }

    if let value = object as? T {
      return value
    } else if let string = object as? String, let value = T(string) {
      return value
    }

    return nil
  }
}
