import Combine
import UIKit

public extension Publisher {
  func ignoreNil<T>() -> Publishers.CompactMap<Self, T> where Output == T? {
    compactMap { $0 }
  }
}

public extension UIView {
  static func animate(
    _ duration: TimeInterval,
    delay: TimeInterval = 0,
    _ animations: @escaping () -> Void
  ) -> Future<Bool, Never> {
    .init { promise in
      UIView.animate(
        withDuration: duration,
        delay: delay,
        animations: animations,
        completion: { promise(.success($0)) }
      )
    }
  }
}

public extension Publisher where Failure == Never {
  func animate(
    _ duration: TimeInterval,
    delay: TimeInterval = 0,
    _ animations: @escaping (Output) -> Void
  ) -> AnyPublisher<Bool, Never> {
    flatMap { output in
      UIView.animate(duration, delay: delay, { animations(output) })
    }
    .eraseToAnyPublisher()
  }
}

public extension Publisher {
  func receiveOutput(_ callback: @escaping (Output) -> Void) -> AnyPublisher<Output, Failure> {
    handleEvents(receiveOutput: { output in
      callback(output)
    })
    .eraseToAnyPublisher()
  }
}

public extension Future {
  static func deferred(
    _ attemptToFulfill: @escaping (@escaping (Result<Output, Failure>) -> Void) -> Void
  ) -> AnyPublisher<Output, Failure> {
    Deferred {
      Future(attemptToFulfill)
    }.eraseToAnyPublisher()
  }
}

public extension AnyPublisher {
  static func success(_ value: Output) -> AnyPublisher<Output, Failure> {
    Just(value).setFailureType(to: Failure.self).eraseToAnyPublisher()
  }
  
  static func fail(_ error: Failure) -> AnyPublisher<Output, Failure> {
    Fail<Output, Failure>(error: error).eraseToAnyPublisher()
  }
}

extension Publisher {
  /// If `Other` emits before `Self`, when `Self` emits it will emit a value of the latest from `Other`.
  /// This is unlike the behavior of RxSwift's withLatestFrom, where this scneario would end up not emitting any values.
  public func withLatestFrom<Other: Publisher, Result>(
    _ other: Other,
    resultSelector: @escaping (Output, Other.Output) -> Result
  ) -> AnyPublisher<Result, Failure> where Self.Failure == Other.Failure {
    Publishers.CombineLatest(map { ($0, arc4random()) }, other)
      .removeDuplicates(by: { $0.0.1 == $1.0.1 })
      .map { ($0.0, $1) }
      .map(resultSelector)
      .eraseToAnyPublisher()
  }
  
  public func withLatestFrom<Other: Publisher>(_ other: Other) -> AnyPublisher<(Output, Other.Output), Failure>
    where Self.Failure == Other.Failure
  {
    withLatestFrom(other) { ($0, $1) }
  }

  public func withLatestFrom<Other: Publisher>(_ other: Other) -> AnyPublisher<Other.Output, Failure>
    where Self.Failure == Other.Failure
  {
    withLatestFrom(other) { $1 }
  }
}
