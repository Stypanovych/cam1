
import CoreGraphics
import CoreImage

// MARK: - Filterable
public protocol Filterable {}

extension Filterable {
  public func filter(@FilterBuilder _ filterBuilder: () -> Filter<Self>) -> Self {
    filterBuilder()(self)
  }

  public func filter(@FilterBuilder _ filterBuilder: (Self) -> Filter<Self>) -> Self {
    filterBuilder(self)(self)
  }
}

// MARK: - CIImage + Filterable
extension CIImage: Filterable {}
//import CoreGraphics
//
//// MARK: - Filterable
//public protocol Filterable { }
//
//extension Filterable {
//  public typealias Getter<T> = () -> (T)
//  public typealias Applier<T> = (Filter<T>) -> Void
//
//  public func filter(_ scope: (Applier<Self>) -> Void) -> Self {
//    var image = self
//    let applier = { (filter: Filter<Self>) in
//      image = filter(image)
//    }
//    scope(applier)
//    return image
//  }
//
//  public func filter(_ scope: (Applier<Self>, Getter<Self>) -> Void) -> Self {
//    var image = self
//    let applier = { (filter: Filter<Self>) in
//      image = filter(image)
//    }
//    let getter = { image }
//    scope(applier, getter)
//    return image
//  }
//}
