import Foundation
import CoreGraphics
import Gen

//extension Gen {
//  public func run<G: RandomNumberGenerator>(using rng: inout G?) -> Value {
//    guard var rng = rng else { return run() }
//    return run(using: &rng)
//  }
//}

public final class RandomNormal {
  public static let shared = RandomNormal()
//  static var generate: Double { shared.generate }
  // stored properties
  private var s : Double = 0.0
  private var v2 : Double = 0.0
  private var cachedNumberExists = false

  private init() { }
  // (read-only) computed properties
  public func run(_ rng: inout AnyRandomNumberGenerator) -> Double  {
    var u1, u2, v1, x : Double
    if !cachedNumberExists {
      repeat {
        u1 = Gen.double(in: 0...1).run(using: &rng)
        u2 = Gen.double(in: 0...1).run(using: &rng)
        v1 = 2 * u1 - 1
        v2 = 2 * u2 - 1
        s = v1 * v1 + v2 * v2
      } while (s >= 1 || s == 0)
      x = v1 * sqrt(-2 * log(s) / s)
    } else {
      x = v2 * sqrt(-2 * log(s) / s)
    }
    cachedNumberExists = !cachedNumberExists
    return x
  }
  
  public func run(m: Double, v: Double, _ rng: inout AnyRandomNumberGenerator) -> Double {
    run(&rng) * v + m
  }
}

//public extension Gen {
//  static func normal(m: Double, v: Double) -> Gen<Double> {
//    var s: Double = 0.0
//    var v2: Double = 0.0
//    var cachedNumberExists = false
//
//    return .init { rng in
//      var u1, u2, v1, x : Double
//      if !cachedNumberExists {
//        repeat {
//          u1 = Gen.double(in: 0...1).run(using: &rng)
//          u2 = Gen.double(in: 0...1).run(using: &rng)
//          v1 = 2 * u1 - 1
//          v2 = 2 * u2 - 1
//          s = v1 * v1 + v2 * v2
//        } while (s >= 1 || s == 0)
//        x = v1 * sqrt(-2 * log(s) / s)
//      } else {
//        x = v2 * sqrt(-2 * log(s) / s)
//      }
//      cachedNumberExists = !cachedNumberExists
//      return x
//    }
//  }
//}

public extension Double {
  var cgfloat: CGFloat {
    return CGFloat(self)
  }
  
  static func normal(m: Self, v: Self) -> Self {
    var rng = AnyRandomNumberGenerator(Xoshiro(seed: .random(in: UInt64.min...UInt64.max)))
    return RandomNormal.shared.run(
      m: m,
      v: v,
      &rng
    )
  }
}

public extension CGFloat {
  static func normal(m: Self, v: Self) -> Self {
    Self(Double.normal(m: m, v: v))
  }

  static func uniform(in range: ClosedRange<Self>) -> Self {
    return CGFloat.random(in: range)
  }
}
