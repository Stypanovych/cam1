@propertyWrapper
public struct OptionalEquatableNoop<T>: Equatable {
  public var wrappedValue: T?
  
  public init(_ wrappedValue: T?) {
    self.wrappedValue = wrappedValue
  }
  
  public static func == (lhs: OptionalEquatableNoop<T>, rhs: OptionalEquatableNoop<T>) -> Bool {
    switch lhs.wrappedValue {
    case .none:
      switch rhs.wrappedValue {
      case .none: return true
      case .some: return false
      }
    case .some:
      switch rhs.wrappedValue {
      case .none: return false
      case .some: return true
      }
    }
  }
}

@propertyWrapper
public struct EquatableNoop<T>: Equatable {
  public var wrappedValue: T
  
  public init(_ wrappedValue: T) {
    self.wrappedValue = wrappedValue
  }
  
  public static func == (lhs: EquatableNoop<T>, rhs: EquatableNoop<T>) -> Bool {
    return true
  }
}
