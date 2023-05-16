import Foundation

extension DispatchQueue {
  public typealias QOS = DispatchQoS
  
  public enum Order {
    case concurrent
    case serial(_ name: String)
    
    public func queue(for qos: QOS) -> DispatchQueue {
      switch self {
      case let .serial(name): return DispatchQueue(label: name, qos: qos)
      case .concurrent: return DispatchQueue.global(qos: qos.qosClass)
      }
    }
  }
  
  public static func background(_ order: Order, _ qos: QOS) -> DispatchQueue {
    return order.queue(for: qos)
  }
}
