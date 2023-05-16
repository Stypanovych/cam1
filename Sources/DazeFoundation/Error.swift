import Foundation
import System

public extension Error {
  var equatable: EquatableError {
    .init(error: self)
  }
  
  static func generic(_ description: String) -> GenericError {
    return GenericError(description)
  }
}

public struct GenericError: Error, CustomStringConvertible {
  public let message: String
  public let fileId: String
  public let function: String
  public let line: Int
  
  public init(
    _ message: String,
    fileId: String = #fileID,
    function: String = #function,
    line: Int = #line
  ) {
    self.message = message
    self.fileId = fileId
    self.function = function
    self.line = line
  }

  private var fileUrl: URL { URL(fileURLWithPath: fileId) }
  private var fileName: String { fileUrl.pathComponents.last ?? "unknown_file" }
  private var moduleName: String { fileUrl.pathComponents[safe: 1] ?? "unknown_module" }
  public var description: String { "📦\(moduleName) 📝\(fileName) #️⃣\(line) → \(message)" }
}

public struct EquatableError: Error, Equatable, CustomStringConvertible {
  public let id = UUID()
  public let error: Error?
  
  public var description: String {
    (error as CustomStringConvertible?)?.description ?? "EquatableError"
  }
  
  public init() {
    self.error = nil
  }
  
  public init(error: Error) {
    self.error = error
  }
  
  public static func == (lhs: EquatableError, rhs: EquatableError) -> Bool {
    lhs.id == rhs.id
  }
}



//@propertyWrapper
//public struct EquatableShield<T>: Equatable {
//  public var wrappedValue: T {
//    didSet {
//      print("trigger")
//      substitute = .unique
//    }
//  }
//  private var substitute: String = .unique
//
//  public init(wrappedValue: T) {
//    self.wrappedValue = wrappedValue
//  }
//
////  mutating func reload() {
////    substitute = .unique
////  }
//
//  public static func == (lhs: Self, rhs: Self) -> Bool {
//    lhs.substitute == rhs.substitute
//  }
//}

// try to get from cache, if not insert on background thread
//public class Cache<Key: Hashable, Value> {
//  private var dict: [Key: Value] = [:]
//
//  public func `get`(
//    _ key: Key,
//    value: () -> Value
//  ) -> Value {
//    guard let oldValue = dict[key] else {
//      let newValue = value()
//      dict[key] = newValue
//      return newValue
//    }
//    return oldValue
//  }
//
//  public func `get`<SomeScheduler: Scheduler>(
//    _ key: Key,
//    value: @escaping () -> Value,
//    on scheduler: SomeScheduler
//  ) -> Future<Value, Never> {
//    guard let oldValue = dict[key] else {
//      return Future { promise in
//        scheduler.schedule {
//          let newValue = value()
//          self.dict[key] = newValue
//          promise(.success(newValue))
//        }
//      }
//    }
//    return Future { $0(.success(oldValue)) }
//  }
//}
