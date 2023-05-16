infix operator ~~
public func ~~<T>(test: T, closure: (T) -> Void) -> T {
  closure(test)
  return test
}

import Foundation

public extension URL {
  static func documents(relativePath path: String) -> URL {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    return documents.appendingPathComponent(path)
  }
}

public extension Result {
  var value: Success? { try? get() }
}

public extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  subscript (safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

public extension Array {
  mutating func remove(at indices: [Int]) {
    for index in indices.sorted(by: >) {
      remove(at: index)
    }
  }
}

public extension Array where Element: Hashable {
  mutating func remove(elements: Set<Element>) {
    let indicesToRemove = indices.filter {
      elements.contains(self[$0])
    }
    remove(at: indicesToRemove)
  }
}
