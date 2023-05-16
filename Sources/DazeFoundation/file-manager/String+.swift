import Foundation

extension String {
  public static var unique: String { UUID().uuidString }
  
  func removing(prefix: String) -> String {
    guard hasPrefix(prefix) else { return self }
    return String(dropFirst(prefix.count))
  }
  
  func removing(suffix: String) -> String {
    guard hasSuffix(suffix) else { return self }
    return String(dropLast(suffix.count))
  }
  
  func appending(prefix: String) -> String {
    guard !hasPrefix(prefix) else { return self }
    return prefix + self
  }
  
  func appending(suffix: String) -> String {
    guard !hasSuffix(suffix) else { return self }
    return appending(suffix)
  }
}

extension URL {
  static func expand(path: String) -> String {
    var path = path
//    switch LocationType.kind {
//    case .file:
//        guard !path.isEmpty else {
//            throw LocationError(path: path, reason: .emptyFilePath)
//        }
//    case .folder:
//        if path.isEmpty { path = fileManager.currentDirectoryPath }
//        if !path.hasSuffix("/") { path += "/" }
//    }

    if path.hasPrefix("~") {
      let homePath = ProcessInfo.processInfo.environment["HOME"]!
      path = homePath + path.dropFirst()
    }
    while let parentReferenceRange = path.range(of: "../") {
      let folderPath = String(path[..<parentReferenceRange.lowerBound])
      let parentPath = makeParentPath(for: folderPath) ?? "/"
      path.replaceSubrange(..<parentReferenceRange.upperBound, with: parentPath)
    }
    return path
  }
  
  static func makeParentPath(for path: String) -> String? {
    guard path != "/" else { return nil }
    let url = URL(fileURLWithPath: path)
    let components = url.pathComponents.dropFirst().dropLast()
    guard !components.isEmpty else { return "/" }
    return "/" + components.joined(separator: "/") + "/"
  }
}
