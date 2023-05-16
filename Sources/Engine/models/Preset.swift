import DazeFoundation
import Foundation
import ComposableArchitecture

extension User {
    public struct Preset: Hashable, Identifiable {
        public static func == (lhs: User.Preset, rhs: User.Preset) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.name == rhs.name &&
                   lhs.creationDate == rhs.creationDate &&
                   lhs.parameters == rhs.parameters
        }
        
        public var id: UUID
        public var name: String
        public var creationDate: Date
        public var parameters: FilteredImage.Parameters
        
        public init(
            id: UUID,
            name: String,
            creationDate: Date,
            parameters: FilteredImage.Parameters
        ) {
            self.id = id
            self.name = name
            self.creationDate = creationDate
            self.parameters = parameters
        }
    }
}

public enum Preset: Hashable {
  case custom(FilteredImage.Parameters)
  case system(_ name: String, FilteredImage.Parameters)
  case user(User.Preset)
  
  public var parameters: FilteredImage.Parameters {
    switch self {
    case let .custom(parameters): return parameters
    case let .system(_, parameters): return parameters
    case let .user(preset): return preset.parameters
    }
  }
  
  public var name: String {
    switch self {
    case .custom: return "new"
    case let .system(name, _): return name
    case let .user(preset): return preset.name
    }
  }
  
  public var userPreset: User.Preset? {
    guard case let .user(preset) = self else { return nil }
    return preset
  }
  
  public static var system1: Self {
    .system(
      "system1",
      .init(
        blurRadius: 0.1,
        chromaScale: 0.5,
        dustOpacity: 1.0,
        dustParticleIntensity: 1.0,
        dustHairIntensity: 1.0,
        glowOpacity: 0.4,
        glowRadius: 0.5,
        glowThreshold: 0.5,
        grainOpacity: 0.5,
        grainSize: 0.5,
        lightLeakOpacity: 1.0,
        lightLeak: Resources.Leak.all[0].resource,
        lookup: Resources.Lut.faded.resource,
        lookupIntensity: 1.0,
        vignetteIntensity: 1.0,
        stampFont: .digital,
        stampColor: 0.5,
        stampDateVisible: true,
        stampTimeVisible: true
      )
    )
  }
  
//  public static func == (lhs: Self, rhs: Self) -> Bool {
//    return lhs.id == rhs.id
//  }
//
//  public func hash(into hasher: inout Hasher) {
//    hasher.combine(id)
//  }
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.custom, .custom): return true
    case let (.system(name1, _), .system(name2, _)): return name1 == name2
    case let (.user(preset1), .user(preset2)): return preset1.id == preset2.id
    default: return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch self {
    case .custom: hasher.combine(0)
    case let .system(name, _): hasher.combine(name)
    case let .user(preset): hasher.combine(preset.id)
    }
  }
}

