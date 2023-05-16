@propertyWrapper
struct Clamped<T: Comparable> {
  private var value: T
  let range: ClosedRange<T>

  var wrappedValue: T {
    get { value }
    set { value = range.clamp(value) }
  }

  init(wrappedValue value: T, _ range: ClosedRange<T>) {
    self.value = range.clamp(value)
    self.range = range
  }
}

public extension ClosedRange {
  func clamp(_ value: Bound) -> Bound {
    Swift.min(Swift.max(value, lowerBound), upperBound)
  }
}

public extension Comparable {
  func clamped(by range: ClosedRange<Self>) -> Self {
    range.clamp(self)
  }
}

public extension ClosedRange where Bound: FloatingPoint {
  static var normal: Self { 0 ... 1 }
}
