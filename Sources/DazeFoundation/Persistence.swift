import Foundation
//import StoreKit
import KeychainAccess

public struct StorageLocation {
  public let store: (_ data: Data, _ key: String) -> Void
  public let retrieve: (_ key: String) -> Data?
  
  public static let memory: Self = {
    var dict: [String: Data] = [:]
    return .init(
      store: { data, key in dict[key] = data },
      retrieve: { key in dict[key] }
    )
  }()
  
  public static let userDefaults: Self = .init(
    store: { data, key in
      UserDefaults.standard.set(data, forKey: key)
    },
    retrieve: { key in
      UserDefaults.standard.object(forKey: key) as? Data
    }
  )
  
  public static let keychain: Self = .init(
    store: { data, key in
      let keychain = Keychain()
      keychain[key] = String(data: data, encoding: .utf8)
    },
    retrieve: { key in
      let keychain = Keychain()
      return keychain[key]?.data(using: .utf8)
    }
  )
}

@propertyWrapper
public struct Persist<T: Codable> {
  private let location: StorageLocation
  private let key: String
  private let defaultValue: T
  
  public var wrappedValue: T {
    set {
      guard let data = try? JSONEncoder().encode(newValue) else { return }
      //UserDefaults.standard.set(data, forKey: key)
      location.store(data, key)
    }
    get {
      guard let data = location.retrieve(key) else { return defaultValue }
      return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }
  }
  
  public init(_ location: StorageLocation, key: String, defaultValue: T) {
    self.location = location
    self.key = key
    self.defaultValue = defaultValue
  }
}

public protocol Default {
  static var `default`: Self { get }
}

public class Persistent<Model: Default> {
  public typealias Key = String
  private typealias StorageAssignments = [AnyKeyPath: (StorageLocation, Key)]
  private var storageAssignments: StorageAssignments
  public private(set) var model: Model = .default
  
  private init(storageAssignments: StorageAssignments) {
    self.storageAssignments = storageAssignments
  }
  
  public init() {
    self.storageAssignments = [:]
  }
  
  public func assign<Value: Decodable>(
    storage: StorageLocation,
    key: Key,
    to keyPath: WritableKeyPath<Model, Value>
  ) -> Persistent<Model> {
    storageAssignments[keyPath] = (storage, key)
    try! read(keyPath)
    return self
  }

  public func write<Value: Encodable>(
    _ keyPath: WritableKeyPath<Model, Value>,
    value: Value
  ) throws -> Model {
    guard let (storage, key) = storageAssignments[keyPath] else { throw GenericError.noAssignmentForKeyPath }
    let data = try JSONEncoder().encode(value)
    storage.store(data, key)
    model[keyPath: keyPath] = value
    return model
  }
  
  @discardableResult
  public func read<Value: Decodable>(_ keyPath: WritableKeyPath<Model, Value>) throws -> Value {
    guard let (storage, key) = storageAssignments[keyPath] else { throw GenericError.noAssignmentForKeyPath }
    guard let data = storage.retrieve(key) else { return model[keyPath: keyPath] }
    let value = try JSONDecoder().decode(Value.self, from: data)
    model[keyPath: keyPath] = value
    return value
  }
}

fileprivate extension GenericError {
  static var noAssignmentForKeyPath: Self { .init("no assignment for key path") }
}
