public struct Selection<T: Hashable>: Hashable {
  public let element: T
  public let isSelected: Bool
  
  public init(
    element: T,
    isSelected: Bool
  ) {
    self.element = element
    self.isSelected = isSelected
  }
  
  public func map<U: Hashable>(_ transform: (T) -> U) -> Selection<U> {
    return .init(element: transform(element), isSelected: isSelected)
  }
  
  public func toggled() -> Selection<T> {
    .init(element: element, isSelected: !isSelected)
  }
  
  public func selected() -> Selection<T> {
    .init(element: element, isSelected: true)
  }
  
  public func unselected() -> Selection<T> {
    .init(element: element, isSelected: false)
  }
  
  public static func selected(_ element: T) -> Selection<T> {
    .init(element: element, isSelected: true)
  }
  
  public static func unselected(_ element: T) -> Selection<T> {
    .init(element: element, isSelected: false)
  }
}

public extension Array where Element: Hashable {
  func unselected() -> [Selection<Element>] {
    map { Selection.unselected($0) }
  }
}

public enum Usage<T> {
  case disabled
  case enabled(T)
  
  public var enabled: Bool {
    switch self {
    case .disabled: return false
    case .enabled: return true
    }
  }
  
  public var value: T? {
    switch self {
    case .disabled: return nil
    case let .enabled(value): return value
    }
  }
  
  public func map<U>(_ transform: (T) -> (U)) -> Usage<U> {
    switch self {
    case .disabled: return .disabled
    case let .enabled(value): return .enabled(transform(value))
    }
  }
}

extension Usage: Equatable where T: Equatable {}
