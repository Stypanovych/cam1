import ComposableArchitecture
import Combine

public enum SelectionTracker<T: Hashable & Identifiable> {
  public struct State: Equatable {
    public let canSelect: Bool
    public let selectionCapacity: Int?
    public var selectedElements: Set<T>
    public let elements: IdentifiedArrayOf<T>
    
    // non computed property would end up being computed every init anyway due to single source of truth implications
    // element selected -> reconfigure elements without reloading collection
    public var selection: [Selection<T>] { elements.map { .init(element: $0, isSelected: selectedElements.contains($0)) } }
    
    public init(
      canSelect: Bool = false,
      selectedElements: Set<T>,
      selectionCapacity: Int? = nil,
      elements: IdentifiedArrayOf<T> = []
    ) {
      self.canSelect = canSelect
      self.selectionCapacity = selectionCapacity
      self.selectedElements = selectedElements
      self.elements = elements
    }
  }
  
  public typealias Action = T.ID
  
  public static func reducer() -> Reducer<State, Action, Void> {
    return Reducer { state, id, _ in
      guard
        state.canSelect,
        let element = state.elements[id: id]
      else { return .none }
      if state.selectedElements.contains(element) {
        state.selectedElements.remove(element)
        return .none
      } else if
        let selectionCapacity = state.selectionCapacity,
        state.selectedElements.count >= selectionCapacity
      {
        return .none
      }
      state.selectedElements.insert(element)
      return .none
    }
  }
  
  public typealias Store = ComposableArchitecture.Store<State, Action>
  public typealias ViewStore = ComposableArchitecture.ViewStore<State, Action>
}
