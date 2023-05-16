import Foundation
import Files

@dynamicMemberLookup
public struct File {
  private let pointer: Pointer
  private let data: Data

  public init(pointer: Pointer, data: Data) {
    self.pointer = pointer
    self.data = data
  }

  public func store() throws {
    guard let directory = self.directory else { throw GenericError("no directory to store in") }
    try directory.create()
    try data.write(to: self.url, options: .atomicWrite)
  }

  subscript<T>(dynamicMember member: KeyPath<Pointer, T>) -> T {
    return pointer[keyPath: member]
  }
}

public extension File {
  struct Pointer {
    public var name: String
    public var ext: Extension?
    public var directory: Directory?
    let fileManager: FileManager

    public init(
      directory: Directory?,
      name: String,
      ext: Extension?,
      fileManager: FileManager = .default
    ) {
      self.directory = directory
      self.name = name
      self.ext = ext
      self.fileManager = fileManager
      path = Self.createPath(directory: directory, name: name, ext: ext)
    }
    
    public init(url: URL, fileManager: FileManager = .default) {
      let urlWithoutExt = url.deletingPathExtension()
      self.name = urlWithoutExt.lastPathComponent
      self.ext = (url.pathExtension == "") ? nil : .init(stringLiteral: url.pathExtension)
      self.directory = Directory(url: urlWithoutExt.deletingLastPathComponent())
      self.fileManager = fileManager
      path = Self.createPath(directory: directory, name: name, ext: ext)
    }
    
    public init(path: String, fileManager: FileManager = .default) {
      self.init(url: URL(fileURLWithPath: path), fileManager: fileManager)
    }
    
    private static func createPath(
      directory: Directory?,
      name: String,
      ext: Extension?
    ) -> String {
      (directory?.path ?? "").removing(suffix: "/") + "/" + name + (ext.map { "." + $0.string } ?? "")
    }

    public var url: URL { URL(fileURLWithPath: path) }
    public let path: String
    public var hasFile: Bool { fileManager.fileExists(atPath: path) }
    
    public func file(with data: Data) -> File {
      return File(pointer: self, data: data)
    }

    public func file() throws -> File {
      guard let data = fileManager.contents(atPath: path) else { throw GenericError("no data at file path") }
      return File(pointer: self, data: data)
    }
    
    public func move(to newLocation: File.Pointer) throws {
      try fileManager.moveItem(at: url, to: newLocation.url)
    }
    
    public func delete() throws {
      try fileManager.removeItem(at: url)
    }
    
    public func data() -> Data? {
      fileManager.contents(atPath: path)
    }

    public func removingParent(directory: Directory) -> File.Pointer {
      return File.Pointer(
        directory: self.directory?.removingParent(directory: directory),
        name: name,
        ext: ext
      )
    }

    public func addingParent(directory: Directory) -> File.Pointer {
      return File.Pointer(
        directory: self.directory?.addingParent(directory: directory),
        name: name,
        ext: ext
      )
    }
  }
}

public extension File.Pointer {
  struct Extension: ExpressibleByStringLiteral {
    public let string: String

    public init(stringLiteral value: String) {
      string = value
    }

    public static let jpg: Self = "jpg"
    public static let png: Self = "png"
  }
}

extension File.Pointer: Hashable {
  public static func == (lhs: File.Pointer, rhs: File.Pointer) -> Bool {
    return lhs.path == rhs.path
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(path)
  }
}

// v2

//@dynamicMemberLookup
//public struct File {
//  private let pointer: Pointer
//  private let data: Data
//
//  public init(pointer: Pointer, data: Data) throws {
//    self.pointer = pointer
//    self.data = data
//  }
//
//  public func delete() throws {
//    try pointer.base.delete()
//  }
//
//  public func move(to newLocation: File.Pointer) throws {
//    guard let folder = newLocation.directory?.base else { return }
//    try pointer.base.move(to: folder)
//  }
//
//  public func store() throws {
//    try pointer.base.write(data)
//  }
//
//  subscript<T>(dynamicMember member: KeyPath<Pointer, T>) -> T {
//    return pointer[keyPath: member]
//  }
//}
//
//public extension File {
//  struct Pointer {
//    public var name: String { base.nameExcludingExtension }
//    public var ext: Extension? { base.extension.map(Extension.init) }
//    public var directory: Directory? { base.parent.map(Directory.init) }
//    let base: Files.File
//
//    public init(directory: Directory?, name: String, ext: Extension?, fileManager: FileManager = .default) throws {
//      let fileName = name + "." + (ext?.string ?? "")
//      base = try directory.map { try $0.base.file(named: fileName) }
//      ?? Files.File(path: fileName).managedBy(fileManager)
//    }
//
//    public var url: URL { base.url }
//    public var path: String { base.path }
//
//    public func file() throws -> File {
//      try File(pointer: self, data: base.read())
//    }
//
//    public func removingParent(directory: Directory) throws -> File.Pointer {
//      return try File.Pointer(
//        directory: try self.directory?.removingParent(directory: directory),
//        name: name,
//        ext: ext
//      )
//    }
//
//    public func addingParent(directory: Directory) throws -> File.Pointer {
//      return try File.Pointer(
//        directory: try self.directory?.addingParent(directory: directory),
//        name: name,
//        ext: ext
//      )
//    }
//  }
//}
//
//public extension File.Pointer {
//  struct Extension: ExpressibleByStringLiteral {
//    public let string: String
//
//    public init(stringLiteral value: String) {
//      string = value
//    }
//
//    public static let jpg: Self = "jpg"
//    public static let png: Self = "png"
//  }
//}
//
//extension File.Pointer: Hashable {
//  public static func == (lhs: File.Pointer, rhs: File.Pointer) -> Bool {
//    return lhs.path == rhs.path
//  }
//
//  public func hash(into hasher: inout Hasher) {
//    hasher.combine(path)
//  }
//}

// v2

//public extension File.Pointer {
//  var url: URL {
//    return URL(fileURLWithPath: path)
//  }
//
//  var exists: Bool {
//    return FileManager.default.fileExists(atPath: path)
//  }
//}
//
//@dynamicMemberLookup
//public struct File {
//  public let pointer: File.Pointer
//  public let data: Data
//
//  public init(pointer: File.Pointer, data: Data) {
//    self.pointer = pointer
//    self.data = data
//  }
//
//  public init(directory: Directory?, name: String, ext: Extension, data: Data) {
//    self.pointer = .init(directory: directory, name: name, ext: ext)
//    self.data = data
//  }
//
//  public var path: String {
//    return pointer.path
//  }
//
//  subscript<T>(dynamicMember member: KeyPath<Pointer, T>) -> T {
//    return pointer[keyPath: member]
//  }
//}
//
//public extension File {
//  struct Pointer {
//    public let name: String
//    public let ext: String?
//    public let directory: Directory?
//
//    // non-nil directory...use .none .. idk
//    public init(directory: Directory?, name: String, ext: Extension) {
//      self.name = name
//      self.ext = ext.string
//      self.directory = directory
//    }
//
//    public init(directory: Directory?, name: String, ext: String?) {
//      self.name = name
//      self.ext = ext
//      self.directory = directory
//    }
//
//    public init(url: URL) {
//      let urlWithoutExt = url.deletingPathExtension()
//      self.name = urlWithoutExt.lastPathComponent
//      self.ext = url.pathExtension
//      self.directory = Directory(url: urlWithoutExt.deletingLastPathComponent())
//    }
//
//    public init(string: String) {
//      self.init(url: URL(fileURLWithPath: string))
//    }
//
//    public var path: String {
//      let formattedExt = (ext == nil) ? "" : ("." + ext!)
//      return (directory?.path ?? "") + "/" + name + formattedExt
//    }
//
//    public func removingParent(directory: Directory) -> File.Pointer {
//      return File.Pointer(
//        directory: self.directory?.removingParent(directory: directory),
//        name: name,
//        ext: ext
//      )
//    }
//
//    public func addingParent(directory: Directory) -> File.Pointer {
//      //let newDirectory = (self.directory != nil) ? self.directory!.addingParent(directory: directory) : directory
//      return File.Pointer(
//        directory: self.directory?.addingParent(directory: directory),
//        name: name,
//        ext: ext
//      )
//    }
//
//    public func with(data: Data) -> File {
//      return File(pointer: self, data: data)
//    }
//
//    public func with(ext: File.Extension) -> File.Pointer {
//      return with(ext: ext.string)
//    }
//
//    public func with(ext: String?) -> File.Pointer {
//      return File.Pointer(directory: directory, name: name, ext: ext)
//    }
//
//    public static func `in`(bundle: Bundle, name: String, ext: Extension) -> File.Pointer {
//      let url = bundle.url(forResource: name, withExtension: ext.string)!
//      return File.Pointer(url: url)
//    }
//  }
//}
//
//extension File.Pointer: Hashable {
//  public static func == (lhs: File.Pointer, rhs: File.Pointer) -> Bool {
//    return lhs.path == rhs.path
//  }
//
//  public func hash(into hasher: inout Hasher) {
//    hasher.combine(path)
//  }
//}
//
//extension File {
//  public struct Extension {
//    public let string: String
//
//    public static let jpg: Self = .init(string: "jpg")
//    public static let wav: Self = .init(string: "wav")
//    public static let mp4: Self = .init(string: "mp4")
//  }
//}
//
//extension File.Pointer {
//  public func delete() throws {
//    try FileManager.default.removeItem(at: self.url)
//  }
//
//  public func move(to newLocation: File.Pointer) throws {
//    try FileManager.default.moveItem(at: self.url, to: newLocation.url)
//  }
//
//  public func data() -> Data? {
//    return FileManager.default.contents(atPath: path)
//  }
//}
//
//extension File {
//  public func store() throws {
//    guard let directory = self.directory else { throw NoDirectory() }
//    try directory.create()
//    try data.write(to: self.url, options: .atomicWrite)
//
//    struct NoDirectory: Error {}
//  }
//}
