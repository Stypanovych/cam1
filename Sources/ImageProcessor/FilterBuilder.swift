@resultBuilder
public enum FilterBuilder {
  public static func buildBlock<T>(_ components: Filter<T>...) -> Filter<T> {
    Chain(filters: components).filter
  }
}

/// A convenient way to build a single filter from multiple filters
public func buildFilter<T>(@FilterBuilder _ filterBuilder: () -> Filter<T>) -> Filter<T> {
  filterBuilder()
}

/// A convenient way to build a single filter from multiple filters with the ability to reference the filteree that is passed in
public func buildFilter<T>(@FilterBuilder _ filterBuilder: @escaping (T) -> Filter<T>) -> Filter<T> {
  { image in
    filterBuilder(image)(image)
  }
}

// MARK: - Chain
/// A filter that executes an array of filters in order
struct Chain<T> {
  let filters: [Filter<T>]
}

extension Chain {
  func filter(_ image: T) -> T {
    filters.reduce(image) { filteredImage, filter in
      filter(filteredImage)
    }
  }
}
