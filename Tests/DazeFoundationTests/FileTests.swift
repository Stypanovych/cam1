import XCTest
@testable import DazeFoundation

class MockFileManager: FileManager {
  override func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
    isDirectory?.pointee = true
    return true
  }
}

final class FileTests: XCTestCase {
  func testFile() {
    let directory1 = Directory(path: "/a/b/c")!
    let pointer1 = File.Pointer(directory: directory1, name: "file", ext: .png)
    let pointer2 = File.Pointer(directory: nil, name: "file", ext: "fuck")
    XCTAssertEqual(pointer1.path, "/a/b/c/file.png")
    XCTAssertEqual(pointer2.path, "/file.fuck")
  }
}

final class DirectoryTests: XCTestCase {
  func testDirectory() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    //let fileManager = MockFileManager()
    XCTAssertEqual(Directory(path: "/")?.path, nil)
    XCTAssertEqual(Directory(path: "/a")!.path, "/a/")
    XCTAssertEqual(Directory(path: "/a/")!.path, "/a/")
   // XCTAssertEqual(Directory(path: "a/")!.path, "/a/")
   // XCTAssertEqual(Directory(path: "a")!.path, "/a/")
    XCTAssertEqual(Directory(path: "/a/b/")!.path, "/a/b/")
    
    let parentPath = "/a/b/c"
    let childPath = "/d/e/f/"
    let parentDir = Directory(path: parentPath)!
    let childDir = Directory(path: childPath)!
    let dir = Directory(path: parentPath + childPath)!
    XCTAssertEqual(parentDir.path, parentPath + "/")
    XCTAssertEqual(childDir.path, childPath)
    XCTAssertEqual(dir.path, parentPath + childPath)
    XCTAssertEqual(dir.removingParent(directory: parentDir)!.path, childPath)
    XCTAssertEqual(childDir.addingParent(directory: parentDir), dir)
  }
}
