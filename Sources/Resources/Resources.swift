import Foundation

public struct Resource: Hashable {
  public let name: String
  public let url: URL
  
  public init(url: URL) {
    self.name = url.lastPathComponent
    self.url = url
  }
  
  // URLs can have the same absoluteString but not be equal bc one has baseURL and other doesn't
  public static func == (lhs: Resource, rhs: Resource) -> Bool {
    lhs.name == rhs.name &&
    lhs.url.absoluteString == rhs.url.absoluteString
  }
}

// string -> resources resolved during filtering
public struct Resources {
  static func resource(name: String, subdirectory: String) -> Resource? {
    let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "files/\(subdirectory)")
    return url.map(Resource.init)
  }
  
  static func resources(in subdirectory: String) -> [Resource] {
    return (bundle.urls(forResourcesWithExtension: nil, subdirectory: "files/\(subdirectory)") ?? []).map(Resource.init)
  }
  
  // typealias Lut = Tagged<>
  public struct Lut: Hashable {
    public let resource: Resource
    
    public static func named(_ name: String) -> Lut {
      return Resources
        .resource(name: name, subdirectory: "luts")
        .map(Lut.init) ?? fallback
    }
    
    public static let fallback = Lut(resource: Resources.resource(name: "lut-pastel4.png", subdirectory: "luts")!)
    
    public static let disposable17 = named("lut-disposable17.png")
    public static let disposable18 = named("lut-disposable18.png")
    public static let hybrid1 = named("lut-hybrid1.png")
    public static let pastel4 = named("lut-pastel4.png")
    //public static let disposable1 = named("lut-disposable-1.png")
    public static let disposable4 = named("lut-disposable-4.png")
    //public static let disposable5 = named("lut-disposable-5.png")
    public static let faded = named("lut-faded.png")
    public static let jtree = named("lut-jtree.png")
    //public static let greenShadows = named("lut-green-shadows.png")
    
    public static let all: [Lut] = [disposable17, disposable18, hybrid1, pastel4, disposable4, faded]
  }
  
  public struct Leak: Hashable {
    public let resource: Resource
    
    public static func named(_ name: String) -> Leak {
      return Resources
        .resource(name: name, subdirectory: "light-leaks")
        .map(Leak.init) ?? fallback
    }
    
    public static let fallback = all[0]
    
    public static let all: [Leak] = Resources.resources(in: "light-leaks").map(Leak.init)
  }
  
  public struct Dust: Hashable {
    public let resource: Resource
    
    public static func named(_ name: String) -> Dust {
      return Resources
        .resource(name: name, subdirectory: "dust")
        .map(Dust.init)!
    }
    
    public static let particles = named("particles.mp4")
    public static let hairs = named("hairs.mp4")
  }
  
  public struct Grain: Hashable {
    public let resource: Resource
    
    public static func named(_ name: String) -> Grain {
      return Resources
        .resource(name: name, subdirectory: "grain")
        .map(Grain.init)!
    }
    
    public static let overlay = named("grain1.jpg")
  }
}

public let bundle = Bundle.module
