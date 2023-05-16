import Foundation
import Files

// always an expanded path
// always starts and ends with a slash
public final class Directory {
  let name: String
  let parent: Directory?
  let fileManager: FileManager

  public init(name: String, parent: Directory?, fileManager: FileManager = .default) {
    self.name = name
    self.parent = parent
    self.fileManager = fileManager
    path = Self.createPath(parent: parent, name: name)
  }

  public init?(url: URL, fileManager: FileManager = .default) {
    guard url.pathComponents.count > 1 else { return nil }
    var path = url.path
    if !path.hasSuffix("/") { path += "/" }
    let expandedUrl = URL(fileURLWithPath: URL.expand(path: path))
    self.name = expandedUrl.lastPathComponent
    self.parent = Directory(url: expandedUrl.deletingLastPathComponent(), fileManager: fileManager)
    self.fileManager = fileManager
    self.path = Self.createPath(parent: self.parent, name: self.name)
  }

  public convenience init?(path: String, fileManager: FileManager = .default) {
    self.init(url: URL(fileURLWithPath: path), fileManager: fileManager)
  }
  
  private static func createPath(
    parent: Directory?,
    name: String
  ) -> String {
    (parent?.path ?? "").removing(suffix: "/") + "/" + name + "/"
  }

  public let path: String
  public var url: URL { URL(fileURLWithPath: path) }

  public func exists() -> Bool {
    return fileManager.fileExists(atPath: path)
  }

  public func create() throws {
    guard !exists() else { return }
    try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
  }
}

public extension Directory {
  // TODO: recursively
  func removingParent(directory: Directory) -> Directory? {
    guard path.hasPrefix(directory.path) else { return self }
    let index = path.index(path.startIndex, offsetBy: directory.path.count)
    return Directory(path: String(path[index...]).appending(prefix: "/"))
  }

  func addingParent(directory: Directory) -> Directory? {
    return Directory(path: directory.path.removing(suffix: "/") + path)
  }
}

public extension Directory {
  static func matching(
    _ directory: FileManager.SearchPathDirectory,
    mask: FileManager.SearchPathDomainMask = .userDomainMask
  ) -> Directory {
    let url = FileManager.default.urls(for: directory, in: mask)[0]
    return Directory(url: url)!
  }

  static let documents: Directory = .matching(.documentDirectory)
  static let applicationSupport: Directory = .matching(.applicationSupportDirectory)
  static let temp: Directory = Directory(url: FileManager.default.temporaryDirectory)!
  static let cache: Directory = .matching(.cachesDirectory)
}

extension Directory: Hashable {
  public static func == (lhs: Directory, rhs: Directory) -> Bool {
    return lhs.path == rhs.path
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(path)
  }
}

// v2

//public struct Directory {
//  public var name: String { base.nameExcludingExtension }
//  public var parent: Directory? { base.parent.map(Directory.init(base:)) }
//  let base: Files.Folder
//
//  init(base: Files.Folder) {
//    self.base = base
//  }
//
//  public init(
//    name: String,
//    parent: Directory?,
//    fileManager: FileManager = .default
//  ) throws {
//    let subFolder = try Files.Folder(path: name).managedBy(fileManager)
//    base = try parent.map { try $0.base.subfolder(at: name) } ?? subFolder
//  }
//
//  public init(
//    path: String,
//    fileManager: FileManager = .default
//  ) throws {
//    base = try Files.Folder(path: path).managedBy(fileManager)
//  }
//
//  public var url: URL { base.url }
//  public var path: String { base.path }
//
//  public func removingParent(directory: Directory) throws -> Directory {
//    try Directory(path: base.path(relativeTo: directory.base))
//  }
//
//  public func addingParent(directory: Directory) throws -> Directory {
//    try Directory(base: directory.base.subfolder(at: base.path))
//  }
//
//  // func exists()
//  // func create()
//}
//
//public extension Directory {
//  static let documents: Directory = Directory(base: Files.Folder.documents!)
//}
//
//extension Directory: Hashable {
//  public static func == (lhs: Directory, rhs: Directory) -> Bool {
//    return lhs.path == rhs.path
//  }
//
//  public func hash(into hasher: inout Hasher) {
//    hasher.combine(path)
//  }
//}

// v1

//public final class Directory {
//  let name: String
//  let parent: Directory?
//
//  public init(name: String, parent: Directory?) {
//    self.name = name
//    self.parent = parent
//  }
//
//  public init?(url: URL) {
//    let illegalPaths: Set<String> = ["/", ".", ".."]
//    guard !illegalPaths.contains(url.lastPathComponent) else { return nil }
//    self.name = url.lastPathComponent
//    self.parent = Directory(url: url.deletingLastPathComponent())
//  }
//
//  public convenience init?(string: String) {
//    self.init(url: URL(fileURLWithPath: string))
//  }
//
//  // a/b/c
//  static func from(names: [String]) -> Directory? {
//    var names = names
//    guard let last = names.popLast() else { return nil }
//    return Directory(name: last, parent: .from(names: names))
//  }
//
//  public var path: String {
//    guard let parentPath = parent?.path else { return "/" + name }
//    return parentPath + "/" + name
//  }
//
//  public func exists() -> Bool {
//    return FileManager.default.fileExists(atPath: path)
//  }
//
//  public func create() throws {
//    guard !exists() else { return }
//    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
//  }
//}
//
//public extension Directory {
//  // TODO: recursively
//  func removingParent(directory: Directory) -> Directory? {
//    var comparedDirectory = self
//    var traversedDirectoryNames: [String] = []
//    while directory != comparedDirectory {
//      guard let parentDirectory = comparedDirectory.parent else { break }
//      traversedDirectoryNames.append(comparedDirectory.name)
//      comparedDirectory = parentDirectory
//    }
//    return Directory.from(names: traversedDirectoryNames.reversed())
//  }
//
//  func addingParent(directory: Directory) -> Directory? {
//    return Directory(string: directory.path + self.path)
//  }
//}
//
//public extension Directory {
//  var url: URL {
//    return URL(fileURLWithPath: path)
//  }
//
////  static let app: Directory = {
////    let documentsURL = FileManager.default.urls(for: ., in: .userDomainMask)[0]
////    return Directory(url: documentsURL)!
////  }()
//
//  static let documents: Directory = {
//    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    return Directory(url: documentsURL)!
//  }()
//
//  static let applicationSupport: Directory = {
//    let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
//    return Directory(url: applicationSupportURL)!
//  }()
//
//  static let temp: Directory = {
//    return Directory(url: FileManager.default.temporaryDirectory)!
//  }()
//
//  static let cache: Directory = {
//    let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
//    return Directory(url: cacheURL)!
//  }()
//}
//
//extension Directory: Hashable {
//  public static func == (lhs: Directory, rhs: Directory) -> Bool {
//    return lhs.path == rhs.path
//  }
//
//  public func hash(into hasher: inout Hasher) {
//    hasher.combine(path)
//  }
//}
