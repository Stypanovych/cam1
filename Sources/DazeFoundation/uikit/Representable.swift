import UIKit
import SwiftUI

public struct RepresentableView<T: UIView>: UIViewRepresentable {
  private let view: T

  public init(_ view: T) {
    self.view = view
  }
  
  public func makeUIView(context: Context) -> T {
    return view
  }

  public func updateUIView(_ uiView: T, context: Context) {}
}

//public struct TestRepresentableView<Arg, T: UIView>: UIViewRepresentable {
//  private let view: (Arg) -> T
//
//  public init(_ view: @escaping (Arg) -> T) {
//    self.view = view
//  }
//
//  public func makeUIView(context: Context) -> T {
//    return view(context.)
//  }
//
//  public func updateUIView(_ uiView: T, context: Context) {
//
//  }
//}

public struct RepresentableViewController<T: UIViewController>: UIViewControllerRepresentable {
  public typealias UIViewControllerType = T
  
  private let viewController: T

  public init(_ viewController: T) {
    self.viewController = viewController
  }
  
  public func makeUIViewController(context: Context) -> T {
    viewController
  }
  
  public func updateUIViewController(_ uiViewController: T, context: Context) {}
}

public class ViewController<T: UIView>: UIViewController {
  public override func loadView() {
    view = T()
  }
}
