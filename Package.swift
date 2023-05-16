// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Engine",
  platforms: [.iOS(.v14), .macOS(.v10_15)],
  products: [
      // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "Engine",
      targets: ["Engine"]
    ),
    .library(
      name: "ImageProcessor",
      targets: ["ImageProcessor"]
    ),
    .library(
      name: "Capture",
      targets: ["Capture"]
    ),
    .library(
      name: "DazeFoundation",
      targets: ["DazeFoundation"]
    ),
    .library(
      name: "Resources",
      targets: ["Resources"]
    ),
    .library(
      name: "TestResources",
      targets: ["TestResources"]
    ),
    .library(
      name: "AppFeature",
      targets: ["AppFeature"]
    ),
    .library(
      name: "EditFeature",
      targets: ["EditFeature"]
    ),
    .library(
      name: "MainFeature",
      targets: ["MainFeature"]
    ),
    .library(
      name: "CameraFeature",
      targets: ["CameraFeature"]
    )
  ],
  
  dependencies: [
      // Dependencies declare other packages that this package depends on.
      // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/SnapKit/SnapKit", .exact("5.0.1")),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .exact("0.33.1")),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", .exact("4.2.2")),
    .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
    .package(url: "https://github.com/RevenueCat/purchases-ios", .exact("4.13.0")),
    .package(url: "https://github.com/JohnEstropia/CoreStore", from: "9.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-gen", from: "0.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-overture", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.7.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "Engine",
      dependencies: [
        "DazeFoundation",
        "Capture",
        "SnapKit",
        "ImageProcessor",
        "KeychainAccess",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        "Resources",
        .product(name: "RevenueCat", package: "purchases-ios"),
        "CoreStore"
      ],
      resources: [
        .copy("fonts/DS-DIGII.ttf"),
        .copy("fonts/Dot-Matrix.ttf"),
        .copy("fonts/Jost-Bold.ttf"),
        .copy("fonts/Jost-Medium.ttf"),
        .copy("fonts/Jost-Regular.ttf")
      ]
    ),
    .target(
      name: "Capture",
      dependencies: [
        "DazeFoundation",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "DazeFoundation",
      dependencies: [
        "KeychainAccess",
        "Files",
        "SnapKit",
        .product(name: "Overture", package: "swift-overture"),
        .product(name: "Gen", package: "swift-gen"),
        .product(name: "Tagged", package: "swift-tagged")
      ]
    ),
    .target(
      name: "ImageProcessor",
      dependencies: [
        "DazeFoundation",
        "SnapKit",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "Resources",
      dependencies: [],
      resources: [
        .copy("files")
      ]
    ),
    .target(
      name: "TestResources",
      dependencies: [
        "Engine",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ],
      resources: [
        .copy("files")
      ]
    ),
    .target(
      name: "AppFeature",
      dependencies: [
        "Engine",
        "EditFeature",
        "CameraFeature",
        "MainFeature"
      ],
      path: "Sources/Features/AppFeature"
    ),
    .target(
      name: "EditFeature",
      dependencies: [
        "Engine"
      ],
      path: "Sources/Features/EditFeature"
    ),
    .target(
      name: "CameraFeature",
      dependencies: [
        "Engine"
      ],
      path: "Sources/Features/CameraFeature"
    ),
    .target(
      name: "MainFeature",
      dependencies: [
        "EditFeature",
        "Engine"
      ],
      path: "Sources/Features/MainFeature"
    ),
    .target(
      name: "TestHelpers",
      dependencies: []
    ),
    .testTarget(
      name: "EngineTests",
      dependencies: [
        "Engine",
        "CoreStore",
        "TestHelpers"
      ],
      resources: [
        .copy("Model.sqlite"),
        .copy("Model.xcdatamodeld")
      ]
    ),
    .testTarget(
      name: "DazeFoundationTests",
      dependencies: [
        "DazeFoundation",
        "TestHelpers"
      ]
    ),
  ]
)

//extension Target {
//  static func feature(name) -> Self {
//    .target()
//  }
//}
